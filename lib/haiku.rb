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

require_relative 'poem'
require_relative 'corpus'
require_relative 'syllable_dictionary'

class Haiku < Poem
  def initialize(corpus, dictionary)
    super(corpus)

    raise ArgumentError.new('dictionary must not be nil') if dictionary.nil?
    raise ArgumentError.new('dictionary must be a SyllableDictionary object') if not dictionary.kind_of?(SyllableDictionary)

    @dictionary = dictionary
  end

  def compose(options={})
    line1 = construct_line(5, options)
    line2 = construct_line(7, options.merge({:first_word => last_word(line1)}))
    line3 = construct_line(5, options.merge({:first_word => last_word(line2), :ignore_last_stopword => true}))

    "#{line1.capitalize}\n#{line2}\n#{line3}."
  end

private

  def last_word(line)
    line.gsub(/\(.*?\)/, '').split(' ').last
  end

  def construct_line(num_syllables, options={})
    line = ''
    sanity = 0
    syllables = 0

    while syllables < num_syllables && sanity < 1000
      sanity += 1

      if line.empty? && !options[:first_word].nil?
        word = @corpus.bayesian_unigram(options[:first_word])
      else
        word = @corpus.bayesian_unigram(line)
      end

      word_s = @dictionary.count(word)

      if options[:ignore_last_stopword] && syllables + word_s == num_syllables && @corpus.stopwords.include?(word)
        next
      end

      if syllables + word_s <= num_syllables
        line << word << ' '
        syllables += word_s
      end
    end

    if options[:debug]
      line = line.split(' ').map { |word| word + " (#{@dictionary.count(word)})" }.join(' ')
    end

    line.rstrip
  end
end
