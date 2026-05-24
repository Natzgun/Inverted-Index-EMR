#include <cstdint>
#include <fstream>
#include <iostream>
#include <string>
#include <unordered_map>
#include <vector>
#include <thread>

using std::thread;
using std::string;

class Chunk {
public:
  Chunk(std::uint64_t start, std::uint64_t end) : start(start), end(end) {}
  std::uint64_t size() const { return end - start; }
  std::uint64_t get_start() const { return start; }
  std::uint64_t get_end() const { return end; }
private:
  std::uint64_t start;
  std::uint64_t end;
};

void show_chunks(const std::vector<Chunk>& chunks) {
  for (std::size_t i = 0; i < chunks.size(); ++i) {
    std::cout << "Chunk " << i << " -> [" << chunks[i].get_start() << ", "
              << chunks[i].get_end() << ")\n";
  }
}

void normalize_data(std::vector<char>& data) {
  for (char& c : data) {
    if (c >= 'A' && c <= 'Z') {
      c = c - 'A' + 'a';
    }

    if (c == '.' || c == ',' || c == ';' || c == ':' || c == '!' || c == '?' || c == '-' ||
        c == '(' || c == ')' || c == '"' || c == '\'' || c == '\n' || c == '\t') {
      c = ' ';
    }
  }
}

// thread
void frequency_words(const std::vector<char>& chunk, int chunk_id) {
  std::unordered_map<string, int> freq;
  string filename = "input/" + std::to_string(chunk_id) + "_frequency.txt";
  std::ofstream out(filename);

  string word;

  for (char c : chunk) {
    if (c != ' ') {
      word += c;
    } else if (!word.empty()) {
      freq[word]++;
      word = "";
    }
  }

  for (const auto& pair : freq) {
    out << pair.first << " " << pair.second << "\n";
  }

  out.close();

}

int main() {
  std::ifstream fs("wikipedia/wikipedia.txt", std::ios::binary);
  // std::ifstream fs("file.txt", std::ios::binary);

  if (!fs) {
    std::cerr << "No se pudo abrir archivo\n";
    return 1;
  }

  fs.seekg(0, std::ios::end);
  auto file_size = fs.tellg();
  fs.seekg(0, std::ios::beg);

  std::cout << "Tamaño del archivo: " << file_size << " bytes\n";

  const std::uint64_t chunk_size = 1024ULL * 1024ULL * 100ULL; // 100 MB
  // const std::uint64_t chunk_size = 128ULL; // 128 bytes

  std::vector<Chunk> chunks;

  std::uint64_t start = 0;
  while (start < file_size) {
  // for (std::uint64_t start = 0; start < file_size; start += chunk_size) {
    std::uint64_t end = start + chunk_size;

    if (end > file_size)
      end = file_size;

    fs.clear();
    fs.seekg(end, std::ios::beg);

    int c;
    while (end < file_size && (c = fs.get()) != EOF && c != ' ') {
      ++end;
    }

    Chunk chunk(start, end);
    chunks.push_back(chunk);
    start = end + 1;
  }

  std::vector<thread> threads;

  int chunk_id = 0;
  for (const auto& chunk : chunks) {
    std::vector<char> buffer(chunk.size());
    fs.seekg(chunk.get_start(), std::ios::beg);
    fs.read(&buffer[0], chunk.size());

    normalize_data(buffer);

    threads.emplace_back(frequency_words, std::move(buffer), chunk_id++);

    // std::cout << "Contenido del chunk [" << chunk.get_start() << ", "
    //           << chunk.get_end() << "):\n";
    // std::cout.write(&buffer[0], buffer.size());
    // std::cout << "\n\n";
  }

  for (auto& t : threads) {
    t.join();
  }

  show_chunks(chunks);

  return 0;
}
