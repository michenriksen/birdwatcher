module Birdwatcher
  class WordList
    attr_reader :options, :corpus, :word_list

    def initialize(options)
      @options   = options
      @corpus    = []
      @word_list = {}
    end

    def add_to_corpus(text)
      @corpus << text.to_s
    end

    def process
      words = {}
      corpus.each do |text|
        normalize_and_split(text).each do |word|
          next if exclude_word?(word)
          words.key?(word) ? words[word] += 1 : words[word] = 1
        end
      end
      if options[:min_word_count]
        words.delete_if { |word, count| count < options[:min_word_count].to_i }
      end
      sorted_words = words.sort_by { |word, count| count }.reverse
      if options[:word_cap]
        sorted_words = sorted_words.take(options[:word_cap].to_i)
      end
      @word_list = sorted_words
    end

    private

    def exclusion_list
      if !@exclusion_list
        @exclusion_list = options[:exclude_words] || []
        if options[:stopwords_file] && options[:exclude_stopwords]
          @exclusion_list += File.read(options[:stopwords_file]).split("\n").map do |w|
            w.strip.downcase
          end
        end
        if options[:common_words_file] && options[:exclude_common_words]
          @exclusion_list += File.read(options[:common_words_file]).split("\n").map do |w|
            w.strip.downcase
          end
        end
      end
      @exclusion_list
    end

    def normalize_and_split(text)
      text = text.downcase.strip.gsub(/https?:\/\/[\S]+/, "").gsub(/[^0-9a-z@#_ ]/i, " ")
      text.split(" ").map(&:strip)
    end

    def exclude_word?(word)
      return true if word.empty?
      return true if options[:min_word_length] && word.length < options[:min_word_length]
      return true if options[:exclude_hashtags] && word.start_with?("#")
      return true if options[:exclude_mentions] && word.start_with?("@")
      return true if exclusion_list.include?(word)
      false
    end
  end
end
