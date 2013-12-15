# Copyright (C) 2013 Rusty Gerard
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require 'enumerator'
require 'set'

class Corpus
  # initialize
  #
  # Takes an English text document and reduces it to an ngram language model.
  # TODO: Store ngram frequencies in a Trie instead of an array of Hash tables?
  #
  def initialize(data, stopwords, options={})
    raise ArgumentError.new('data must not be nil') if data.nil?
    raise ArgumentError.new('data must be a String') if not data.kind_of?(String)
    raise ArgumentError.new('data must be in ASCII') if not data.ascii_only?
    raise ArgumentError.new('stopwords must not be nil') if stopwords.nil?
    raise ArgumentError.new('stopwords must be a container that implements include?') if not stopwords.respond_to?(:include?)

    @stopwords = stopwords

    @rawtext = ''
    data.split("\n").each do |line|
      next if line.start_with?('#')
      @rawtext << line << ' '
    end

    # Compute ngram data
    @maxn = options[:maxn] || 3
    @unigrams = Hash.new(0)
    @ngrams = Array.new(@maxn - 1)
    @rawtext.gsub(/\s+/, ' ').split(/\.|\?|\!/).each { |sentence| parse_sentence(sentence) }

    # We're done with the stripped-down data, save a reference to the original data
    @rawtext = data

    # Sort ngrams in descending order
    @unigrams = Hash[@unigrams.sort_by { |k, v| v }.reverse]
    @ngrams.each { |ngram| ngram.each_key { |key| ngram[key] = Hash[ngram[key].sort_by { |k, v| v }.reverse] } }

    # Compute wordcount
    @wordcount = 0
    @unigrams.each { |k, v| @wordcount += v }

    # Detect topic words
    @topic_words = Set.new
    detect_topic_words()

    # Detect named entities
    #@named_entities = Set.new
    #detect_named_entities()
  end

  def to_s
    @rawtext
  end

  def to_hash
    hash = Hash['wordcount', @wordcount, 'topic_words', @topic_words.to_a, 'unigrams', @unigrams]

    @ngrams.each_index do |i|
      case i
      when 0
        key = 'bigrams'
      when 1
        key = 'trigrams'
      else
        key = "#{i + 2}-grams"
      end

      hash[key] = @ngrams[i]
    end

    hash
  end

  def wordcount
    @wordcount
  end

  def stopwords
    @stopwords
  end

  def topic_words
    @topic_words
  end

  def unigrams
    @unigrams
  end

  def bigrams
    @ngrams[0]
  end

  def trigrams
    @ngrams[1]
  end

  # bayesian_unigram
  #
  # Selects a random unigram from the corpus based on the provided ngram using Bayes' theorem.
  #
  # Options
  #   laplace_smoothing  pass-through to random_unigram to optionally disable laplace_smoothing of ngrams (useful for unit testing)
  #
  def bayesian_unigram(ngram, options={:laplace_smoothing => true})
    raise ArgumentError.new('ngram must not be nil') if ngram.nil?
    raise ArgumentError.new('ngram must be a String') if not ngram.kind_of?(String)
    raise ArgumentError.new('ngram must be in ASCII') if not ngram.ascii_only?

    if ngram.strip.empty?
      #return random_unigram(@unigrams, {:wordcount => @wordcount, :omit_stopwords => true})
      return random_unigram(@unigrams, {:wordcount => @wordcount})
    end

    # Reduce the order of the ngram to the maximum recorded by the corpus
    ngram_array = ngram.split(' ').last(@maxn)
    ngram_key = ngram_array.join(' ')

    @ngrams.each do |ngram_hash|
      if ngram_hash.has_key?(ngram_key)
        return random_unigram(ngram_hash[ngram_key], {:laplace_smoothing => options[:laplace_smoothing]})
      end
    end

    # The ngram does not occur in the corpus, reduce its order by 1 and search again
    ngram_array.shift()
    ngram_key = ngram_array.join(' ')
    bayesian_unigram(ngram_key, options)
  end

private

  # parse_sentence
  #
  # Compute ngrams for the sentence and add the frequencies of each ngram to the appropriate Hash table.
  #
  def parse_sentence(sentence)
    words = []
    # Split on non-alphanumeric and apostrophe characters (i.e. preserve words like "don't"), then strip any leading or trailing apostrophes
    sentence.split(/[^a-zA-Z\d']/).each { |word| words << word.strip.downcase.gsub(/\A'|'\Z/, '') unless word =~ /\d/ }
    words.delete('')

    # Accumulate unigram frequencies
    words.each { |word| @unigrams[word] += 1 }

    # Accumulate ngram frequencies
    # TODO: Add a special entry for start-of-sentence ngrams? e.g. 'The quick ...' -> {'$' => {'the' => 1}, 'the' => {'quick' => 1}, ... }
    (2..@maxn).each do |n|
      @ngrams[n-2] = Hash.new if @ngrams[n-2].nil?

      words.each_cons(n) do |cons|
        # Store higher-order ngrams as a unigram key and ngram value, e.g. 'foo bar baz' -> {'foo' => {'bar baz' => 1}}
        #key = cons.shift
        #value = cons.join(' ')

        # Store higher-order ngrams as a key with a unigram value, e.g. 'foo bar baz' -> {'foo bar' => {'baz' => 1}}
        key = cons[0..-2].join(' ')
        value = cons.last

        @ngrams[n-2][key] = Hash.new(0) if not @ngrams[n-2].has_key?(key)
        @ngrams[n-2][key][value] += 1
      end
    end
  end

  # random_unigram
  #
  # Selects a random unigram from an ngram hash based on relative frequency.
  #
  # Examples:
  #   @unigrams = Hash['a' => 1, 'b' => 1, 'c' => 1] then random_unigram(@unigrams) will return 'a', 'b', or 'c' with equal probability.
  #   bigrams = Hash['a' => Hash['b' => 1, 'c' => 3] then random_unigram(bigrams['a']) will return 'b' 25% of the time and 'c' 75% of the time.
  #
  # Options:
  #   wordcount          (integer) the total number of ngrams recorded in the hash, skips computing the size of the ngram hash when provided
  #   laplace_smoothing  (boolean) when true, adds 1 to each frequency count probability of returning a completely random unigram
  #   omit_stopwords     (boolean) when true, ignores common words in the corpus
  #
  def random_unigram(ngram_hash, options={})
    alpha = options[:laplace_smoothing] ? 1 : 0

    wordcount = options[:wordcount]
    stopword_count = 0
    if wordcount.nil? || options[:omit_stopwords]
      wordcount = 0
      ngram_hash.each do |word, freq|
        is_stopword = options[:omit_stopwords] && @stopwords.include?(word)
        wordcount += freq unless is_stopword
        stopword_count += 1 if is_stopword
      end
    end

    wordcount += alpha * (ngram_hash.length - stopword_count)

    index = rand(1..wordcount)
    sum = -alpha
    ngram_hash.each do |word, freq|
      sum += freq + alpha

      if sum >= index
        return word unless options[:omit_stopwords] && @stopwords.include?(word)
      end
    end

    # If laplace_smoothing is enabled, there is a marginal chance to return a random unigram
    random_unigram(@unigrams, {:wordcount => @wordcount})
  end

  # detect_topic_words
  #
  # Finds words in the corpus that are statistically significant using the Z-test method.
  #
  # Options
  #   stddev  The number of standard deviations from the mean that defines a word as statistically significant.
  #
  def detect_topic_words(options={})
    max_stddev = (options[:stddev] || 2.0).to_f

    # Compute descriptive statistics
    mean = @wordcount / @unigrams.length.to_f
    stddev = 0
    @unigrams.each { |k, v| stddev += (v - mean)**2 }
    stddev = Math.sqrt(stddev / (@unigrams.length - 1))
    #stderr = stddev / Math.sqrt(@unigrams.length)

    # Find words with statistically significant wordcounts
    @unigrams.each do |k, v|
      zscore = (v - mean).abs / stddev
      @topic_words << k if zscore >= max_stddev && !@stopwords.include?(k)
    end
  end

  def detect_named_entities
    # TODO: Implement this
  end
end
