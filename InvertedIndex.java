import java.io.IOException;
import java.util.HashSet;
import java.util.Set;
import java.util.StringTokenizer;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.FileSplit;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class InvertedIndex {

    // ─── MAPPER ───────────────────────────────────────────────────────────────
    public static class TokenizerMapper
            extends Mapper<Object, Text, Text, Text> {

        private Text word     = new Text();
        private Text fileName = new Text();
        private Set<String> searchWords = new HashSet<>();

        @Override
        protected void setup(Context context) throws IOException, InterruptedException {
            String wordList = context.getConfiguration().get("search.words", "");
            for (String w : wordList.split(",")) {
                String trimmed = w.trim().toLowerCase();
                if (!trimmed.isEmpty()) {
                    searchWords.add(trimmed);
                }
            }
        }

        @Override
        public void map(Object key, Text value, Context context)
                throws IOException, InterruptedException {

            boolean filterMode = !searchWords.isEmpty();

            // Get filename from processes file
            FileSplit fileSplit = (FileSplit) context.getInputSplit();
            String file = fileSplit.getPath().getName();
            fileName.set(file);

            String line = value.toString().trim();
            if (line.isEmpty()) return;

            // Tomar solo el token de la palabra (ignorar la frecuencia)
            StringTokenizer itr = new StringTokenizer(line);
            if (itr.hasMoreTokens()) {
                String token = itr.nextToken().toLowerCase();

                if (token.isEmpty() || token.matches("\\d+")) return;

                if (filterMode && !searchWords.contains(token)) return;

                word.set(token);
                context.write(word, fileName);
            }
        }
    }

    // ─── COMBINER (its a local reduction per node) ───────────────────────────────
    public static class IndexCombiner
            extends Reducer<Text, Text, Text, Text> {

        private Text result = new Text();

        @Override
        public void reduce(Text key, Iterable<Text> values, Context context)
                throws IOException, InterruptedException {
            java.util.LinkedHashSet<String> fileSet = new java.util.LinkedHashSet<>();
            for (Text val : values) {
                fileSet.add(val.toString());
            }
            result.set(String.join(",", fileSet));
            context.write(key, result);
        }
    }

    // ─── REDUCER ──────────────────────────────────────────────────────────────
    public static class IndexReducer
            extends Reducer<Text, Text, Text, Text> {

        private Text result = new Text();

        @Override
        public void reduce(Text key, Iterable<Text> values, Context context)
                throws IOException, InterruptedException {
            java.util.LinkedHashSet<String> fileSet = new java.util.LinkedHashSet<>();
            for (Text val : values) {
                for (String f : val.toString().split(",")) {
                    fileSet.add(f.trim());
                }
            }
            result.set(String.join(", ", fileSet));
            context.write(key, result);
        }
    }

    // ─── DRIVER ───────────────────────────────────────────────────────────────
    public static void main(String[] args) throws Exception {
        if (args.length < 2) {
            System.err.println("Uso: InvertedIndex <input_path> <output_path> [palabra1,palabra2,...]");
            System.err.println("Ejemplo: InvertedIndex s3://bucket/input s3://bucket/output floréal,decadary,fruitidor");
            System.exit(1);
        }

        Configuration conf = new Configuration();

        if (args.length >= 3 && !args[2].isEmpty()) {
            conf.set("search.words", args[2]);
            System.out.println(">>> Modo filtro activado. Buscando: " + args[2]);
        } else {
            System.out.println(">>> Sin filtro: indexando todas las palabras.");
        }

        Job job = Job.getInstance(conf, "Inverted Index");

        job.setJarByClass(InvertedIndex.class);
        job.setMapperClass(TokenizerMapper.class);
        job.setCombinerClass(IndexCombiner.class);   // local reduction per node
        job.setReducerClass(IndexReducer.class);

        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(Text.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);

        job.setNumReduceTasks(3);

        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));

        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
