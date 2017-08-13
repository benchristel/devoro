require 'pqueue'
require './stopwords'

class WordCounter
  def initialize(words)
    @words = words
  end

  def top(n)
    word_counts = @words.reduce(Hash.new(0)) { |counts, word|
      counts[word] += 1
      counts
    }

    top_words = PQueue.new() { |a, b| a[:rank] <=> b[:rank] }

    word_counts.each { |word, count|
      next if STOPWORDS.include? word
      top_words.push({
        word: word,
        rank: count
      })
    }

    top_words.take(n).reject(&:nil?).map { |w| w[:word] }
  end
end
