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
require_relative '../lib/syllable_dictionary'

class SyllableDictionaryTest < Test::Unit::TestCase

  def setup
    @syllable_dict = SyllableDictionary.new
  end

  def syllable_helper(word, expected)
    result = @syllable_dict.count(word)
    assert_equal expected, result, "incorrect syllable estimate for '#{word}'"
  end

  def test_regular_word
    syllable_helper('book', 1)
  end

  def test_regular_word_silent_e
    syllable_helper('cane', 1)
  end

  def test_regular_word_silent_ed
    syllable_helper('caned', 1)
    syllable_helper('fled', 1)
  end

  def test_regular_word_silent_es
    syllable_helper('canes', 1)
  end

  def test_regular_word_not_silent_e
    syllable_helper('apple', 2)
  end

  def test_regular_word_not_silent_es
    syllable_helper('apples', 2)
  end

  def test_regular_word_leading_y
    syllable_helper('yearn', 1)
  end

  def test_regular_word_hyphenated
    syllable_helper('face-book', 2)
  end

  def test_irregular_word
    # Verify the wrong estimate
    syllable_helper('racecar', 3)

    # Add the irregular word
    @syllable_dict.init_from_collection(Hash['racecar', 2])

    # Test again
    syllable_helper('racecar', 2)
  end

  def test_case_insensitive
    @syllable_dict.init_from_collection(Hash['foo', 99])
    syllable_helper('FOO', 99)
  end

  def test_numerals
    syllable_helper('1999', 0)
  end

  def test_non_word_characters
    syllable_helper("'$tupperware99'", 3)
  end

  def test_string_mixed_bag
    haiku = "Poets don't have a\ndevil-may-care attitude.\n...Inconceivable!"
    @syllable_dict.init_from_collection(Hash['poets', 2, 't', 0])
    syllable_helper(haiku, 17)
  end
end
