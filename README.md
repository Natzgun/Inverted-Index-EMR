# Inverted index

## In your AWS EMR
```console
mkdir -p ~/inverted_index && cd ~/inverted_index
# Clone our repo

# compile code
javac -classpath "$(hadoop classpath)" InvertedIndex.java

# generate jar
jar -cvf inverted_index.jar *.class

# clean your aws s3
aws s3 rm s3://hdfs-emr-bigdeita/output/ --recursive

# run with your custom word
hadoop jar inverted_index.jar InvertedIndex \
  s3://hdfs-emr-bigdeita/input/ \
  s3://hdfs-emr-bigdeita/output/ \
  "erick,big,data,wikipedia,laboratorio"
```

## C++ file
This code processes a only one file of 17GB  wikipedia.txt and later generate 170 files with word counts.
You can use this for the experiment or find other dataset
