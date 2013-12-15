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
require_relative '../lib/corpus'
require_relative '../lib/haiku'
require_relative '../lib/syllable_dictionary'

class HaikuTest < Test::Unit::TestCase

  def setup
    @stopwords = ['the']
    @corpus = Corpus.new('The quick brown fox jumps over the lazy dog.', @stopwords)
    @syllable_dict = SyllableDictionary.new
    @haiku = Haiku.new(@corpus, @syllable_dict)
  end

  def last_word(poem)
    poem.downcase.gsub(/[^a-z ]/, '').split(' ').last
  end

  def test_compose
    poem = @haiku.compose

    assert_equal 3, poem.lines.count, 'Poem contains the wrong number of lines for a haiku'
    assert_equal 17, @syllable_dict.count(poem), 'Poem contains the wrong number of syllables for a haiku'
    assert !@stopwords.include?(last_word(poem)), 'Poem ends with a stopword'
  end

  def test_compose_debug
    poem = @haiku.compose({:debug => true})

    assert_equal 3, poem.lines.count, 'Poem contains the wrong number of lines for a haiku'
    assert_equal 17, @syllable_dict.count(poem), 'Poem contains the wrong number of syllables for a haiku'
    assert !@stopwords.include?(last_word(poem)), 'Poem ends with a stopword'

    @corpus.unigrams.keys.each do |word|
      if poem.include?(word)
        word_with_debug = "#{word} (#{@syllable_dict.count(word)})"
        assert poem.include?(word_with_debug), "Poem does not contain correct debugging information for word '#{word}'"
      end
    end
  end
end
