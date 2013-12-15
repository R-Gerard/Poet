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

require 'test/unit'
require 'set'
require_relative '../lib/corpus'

class CorpusTest < Test::Unit::TestCase

  def setup
    @corpus = Corpus.new('The quick brown fox jumps over the lazy dog.', ['the'])
  end

  def test_wordcount
    assert_equal 9, @corpus.wordcount, 'wordcount is incorrect'
  end

  def test_to_hash
    hash = @corpus.to_hash

    assert hash.has_key?('wordcount'), "field 'wordcount' is missing"
    assert hash.has_key?('topic_words'), "field 'topic_words' is missing"
    assert hash.has_key?('unigrams'), "field 'unigrams' is missing"
    assert hash.has_key?('bigrams'), "field 'bigrams' is missing"
    assert hash.has_key?('trigrams'), "field 'trigrams' is missing"
    assert !hash.has_key?('4-grams'), "unexpected field '4-grams' is present"

    assert_equal 9, hash['wordcount'], 'wordcount is incorrect'

    assert_equal 2, hash['unigrams']['the'], "frequency count for 'the' is incorrect"

    assert hash['bigrams'].has_key?('the'), "missing bigram key 'the'"
    assert_equal 1, hash['bigrams']['the']['quick'], "frequency count for 'the quick' is incorrect"

    assert hash['trigrams'].has_key?('the quick'), "missing trigram key 'the quick'"
    assert_equal 1, hash['trigrams']['the quick']['brown'], "frequency count for 'the quick brown' is incorrect"
  end

  def test_unigrams
    assert_equal 8, @corpus.unigrams.length, 'number of unigrams is incorrect'
    assert_equal 2, @corpus.unigrams['the'], "frequency count for 'the' is incorrect"
    assert_equal 1, @corpus.unigrams['quick'], "frequency count for 'quick' is incorrect"
    assert_equal 1, @corpus.unigrams['brown'], "frequency count for 'brown' is incorrect"
    assert_equal 1, @corpus.unigrams['fox'], "frequency count for 'fox' is incorrect"
    assert_equal 1, @corpus.unigrams['jumps'], "frequency count for 'jumps' is incorrect"
    assert_equal 1, @corpus.unigrams['over'], "frequency count for 'over' is incorrect"
    assert_equal 1, @corpus.unigrams['lazy'], "frequency count for 'lazy' is incorrect"
    assert_equal 1, @corpus.unigrams['dog'], "frequency count for 'dog' is incorrect"
  end

  def test_bigrams
    ['the', 'quick', 'brown', 'fox', 'jumps', 'over', 'lazy'].each do |key|
      assert @corpus.bigrams.has_key?(key), "missing bigram key '#{key}'"
    end

    assert_equal 7, @corpus.bigrams.length, 'number of bigrams is incorrect'
    assert_equal 1, @corpus.bigrams['the']['quick'], "frequency count for 'the quick' is incorrect"
    assert_equal 1, @corpus.bigrams['quick']['brown'], "frequency count for 'quick brown' is incorrect"
    assert_equal 1, @corpus.bigrams['brown']['fox'], "frequency count for 'brown fox' is incorrect"
    assert_equal 1, @corpus.bigrams['fox']['jumps'], "frequency count for 'fox jumps' is incorrect"
    assert_equal 1, @corpus.bigrams['jumps']['over'], "frequency count for 'jumps over' is incorrect"
    assert_equal 1, @corpus.bigrams['over']['the'], "frequency count for 'over the' is incorrect"
    assert_equal 1, @corpus.bigrams['the']['lazy'], "frequency count for 'the lazy' is incorrect"
    assert_equal 1, @corpus.bigrams['lazy']['dog'], "frequency count for 'lazy dog' is incorrect"
  end

  def test_trigrams
    ['the quick', 'quick brown', 'brown fox', 'fox jumps', 'jumps over', 'over the', 'the lazy'].each do |key|
      assert @corpus.trigrams.has_key?(key), "missing trigram key '#{key}'"
    end

    assert_equal 7, @corpus.trigrams.length, 'number of trigrams is incorrect'
    assert_equal 1, @corpus.trigrams['the quick']['brown'], "frequency count for 'the quick brown' is incorrect"
    assert_equal 1, @corpus.trigrams['quick brown']['fox'], "frequency count for 'quick brown fox' is incorrect"
    assert_equal 1, @corpus.trigrams['brown fox']['jumps'], "frequency count for 'brown fox jumps' is incorrect"
    assert_equal 1, @corpus.trigrams['fox jumps']['over'], "frequency count for 'fox jumps over' is incorrect"
    assert_equal 1, @corpus.trigrams['jumps over']['the'], "frequency count for 'jumps over the' is incorrect"
    assert_equal 1, @corpus.trigrams['over the']['lazy'], "frequency count for 'over the lazy' is incorrect"
    assert_equal 1, @corpus.trigrams['the lazy']['dog'], "frequency count for 'the lazy dog' is incorrect"
  end

  def test_ngrams
    @corpus = Corpus.new('The quick brown fox jumps over the lazy dog.', ['the'], {:maxn => 6})
  end

  def test_parse_sentences
    @corpus = Corpus.new('A. B, c? D; e: f! G (h-i) j.', [])

    assert @corpus.bigrams['a'].nil?, 'Sentences were not delimited by periods'
    assert @corpus.bigrams['c'].nil?, 'Sentences were not delimited by question marks'
    assert @corpus.bigrams['f'].nil?, 'Sentences were not delimited by exclamation points'
    assert !@corpus.bigrams['b'].nil?, 'Sentences were delimited by commas'
    assert !@corpus.bigrams['d'].nil?, 'Sentences were delimited by semicolons'
    assert !@corpus.bigrams['e'].nil?, 'Sentences were delimited by colons'
    assert !@corpus.bigrams['g'].nil?, 'Sentences were delimited by opening parenthesis'
    assert !@corpus.bigrams['i'].nil?, 'Sentences were delimited by closing parenthesis'
    assert_equal 6, @corpus.bigrams.length
  end

  def test_no_digits
    @corpus = Corpus.new('January 1st, 1900', [])

    assert_equal 1, @corpus.wordcount, 'wordcount is incorrect'
    assert_equal 1, @corpus.unigrams.length, 'number of unigrams is incorrect'
    assert @corpus.unigrams.include?('january'), "missing unigram key 'january'"
  end

  def test_hyphens
    @corpus = Corpus.new('one-two', [])

    assert_equal 2, @corpus.wordcount, 'wordcount is incorrect'
    assert_equal 2, @corpus.unigrams.length, 'number of unigrams is incorrect'
    assert @corpus.unigrams.include?('one'), "missing unigram key 'one'"
    assert @corpus.unigrams.include?('two'), "missing unigram key 'two'"
  end

  def test_apostrophes
    @corpus = Corpus.new("'Don't'", [])

    assert_equal 1, @corpus.wordcount, 'wordcount is incorrect'
    assert_equal 1, @corpus.unigrams.length, 'number of unigrams is incorrect'
    assert @corpus.unigrams.include?("don't"), "missing unigram key 'don't'"
  end

  def test_one_word_corpus
    @corpus = Corpus.new('a', [])

    assert_equal 1, @corpus.wordcount, 'wordcount is incorrect'
    assert_equal 1, @corpus.unigrams.length, 'number of unigrams is incorrect'
    assert_equal 0, @corpus.bigrams.length, 'number of bigrams is incorrect'
    assert_equal 0, @corpus.trigrams.length, 'number of trigrams is incorrect'
  end

  def test_two_word_corpus
    @corpus = Corpus.new('a b', [])

    assert_equal 2, @corpus.wordcount, 'wordcount is incorrect'
    assert_equal 2, @corpus.unigrams.length, 'number of unigrams is incorrect'
    assert_equal 1, @corpus.bigrams.length, 'number of bigrams is incorrect'
    assert_equal 0, @corpus.trigrams.length, 'number of trigrams is incorrect'
  end

  def test_three_word_corpus
    @corpus = Corpus.new('a b c', [])

    assert_equal 3, @corpus.wordcount, 'wordcount is incorrect'
    assert_equal 3, @corpus.unigrams.length, 'number of unigrams is incorrect'
    assert_equal 2, @corpus.bigrams.length, 'number of bigrams is incorrect'
    assert_equal 1, @corpus.trigrams.length, 'number of trigrams is incorrect'
  end

  def test_bayesian_unigram_emptystringinput
    @corpus = Corpus.new('a a a', [])

    assert_equal 'a', @corpus.bayesian_unigram('', {:laplace_smoothing => false}), 'bayesian_unigram should return a random unigram'

    @corpus = Corpus.new('a b c', [])

    hits = Set.new
    (0..99).each do |i|
       hits << @corpus.bayesian_unigram('', {:laplace_smoothing => true})
    end

    ['a', 'b', 'c'].each do |key|
      assert hits.include?(key), "bayesian_unigram should return a random unigram but did not return '#{key}'"
    end
  end

  def test_bayesian_unigram_unigraminput
    @corpus = Corpus.new('a b c', [])

    assert_equal 'b', @corpus.bayesian_unigram('a', {:laplace_smoothing => false}), "bayesian_unigram should return bigrams['a'].keys.first"
    assert_equal 'c', @corpus.bayesian_unigram('b', {:laplace_smoothing => false}), "bayesian_unigram should return bigrams['b'].keys.first"

    ['a', 'b', 'c'].each do |input|
      hits = Set.new
      (0..99).each do |i|
        hits << @corpus.bayesian_unigram(input, {:laplace_smoothing => true})
      end

      ['a', 'b', 'c'].each do |key|
        assert hits.include?(key), "bayesian_unigram should return a random unigram but did not return '#{key}' with input '#{input}'"
      end
    end
  end

  def test_bayesian_unigram_bigraminput
    @corpus = Corpus.new('a b c d', [])

    assert_equal 'c', @corpus.bayesian_unigram('a b', {:laplace_smoothing => false}), "bayesian_unigram should return trigrams['a b'].keys().first"
    assert_equal 'd', @corpus.bayesian_unigram('b c', {:laplace_smoothing => false}), "bayesian_unigram should return trigrams['b c'].keys().first"
  end

  def test_stopwords
    assert @corpus.stopwords.include?('the'), "missing stopwords key 'the'"
    assert !@corpus.stopwords.include?('fox'), "unexpected stopword key 'fox'"
  end

  def test_topic_words
    rawtext = ''
    rawtext << Array.new(10, 'a b').join(' ') << ' '
    rawtext << ('c'..'z').to_a.join(' ') << ' '

    @corpus = Corpus.new(rawtext, ['a'])

    assert @corpus.topic_words.include?('b'), 'Corpus did not correctly calculate an expected topic word'
    assert !@corpus.topic_words.include?('a'), 'Corpus included a stopword as a topic word'

    ('c'..'z').each do |word|
      assert @corpus.unigrams.include?(word), "missing unigram key '#{word}'"
      assert !@corpus.topic_words.include?(word), "Corpus included the statistically insignificant word '#{word}' as a topic word"
    end
  end
end
