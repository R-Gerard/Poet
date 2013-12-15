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

require_relative 'dictionary'

class SyllableDictionary < Dictionary

  def initialize
    @dictionary = Hash.new
  end

  # init_from_collection
  #
  # Populates the Hash table of irregular words from another Hash.
  #
  def init_from_collection(collection)
    raise ArgumentError.new('collection must not be nil') if collection.nil?
    raise ArgumentError.new('collection must be a Hash') if not collection.kind_of?(Hash)

    @dictionary.merge!(collection)
  end

  # init_from_csv_file
  #
  # Populates the Hash table of irregular words from a comma-separated values file.
  #
  def init_from_csv_file(filename)
    File.open(filename, 'r') do |file|
      file.each_line do |line|
        if line.start_with?('#') then next end

        line.split(',').each_slice(2) do |key, value|
          if not value.strip.match(/\A\d+\Z/) then raise ArgumentError.new("'#{value.strip}' is not a base 10 integer") end
          @dictionary[key.strip.downcase] = value.strip.to_i
        end
      end
    end
  end

  # count
  #
  # Given a string, returns an estimate of the number of syllables in the English word based only on spelling alone
  # (rather than use a spelling-to-phoneme mapping).
  #
  def count(words)
    raise ArgumentError.new('word must not be nil') if words.nil?
    raise ArgumentError.new('word must be a String') if not words.kind_of?(String)
    raise ArgumentError.new('word must be in ASCII') if not words.ascii_only?

    sum = 0
    words.split(/[^a-zA-Z\d]/).each do |word|
      sum += __count(word)
    end

    sum
  end

private

  # __count
  #
  # A modified version of John Talbert's implementation of the GM-STAR syllable estimating algorithm for English words.
  #
  # J. Talburt - The Fesch Index: An Easily Programmable Readability Analysis Algorithm,
  #   SIGDOC '85 Proceedings of the 4th Annual International Conference on Systems Documentation,
  #   pp. 114-122.
  #   http://dl.acm.org/citation.cfm?id=10583
  #
  # Uses a dictionary of syllable counts to override estimates for words that are known to be incorrectly estimated.
  #
  def __count(word)
    word = word.downcase.gsub(/[^a-z]/, '')

    # TODO: Check a vocabulary list to see if the word is a closed form compound word, e.g. 'racecar'
    return @dictionary[word] if @dictionary.has_key?(word)
    return 0 if word.empty?
    return 1 if word.length <= 3

    # Ignore leading 'y'
    if word.start_with?('y')
      word = word[1..-1]
    end

    # Ignore trailing -ed, -es (except -les), and -e (except -le)
    if word.end_with?('ed')
      word = word[0..-3]
    elsif word.end_with?('es') && !word.end_with?('les')
      word = word[0..-3]
    elsif word.end_with?('e') && !word.end_with?('le')
      word.chop!
    end

    # Count the number of vowel singletons and doubletons in the string
    [word.scan(/[aeiouy]{1,2}/).size, 1].max
  end
end
