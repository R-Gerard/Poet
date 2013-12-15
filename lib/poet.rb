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

require 'sinatra'
require 'json'
require_relative 'syllable_dictionary'
require_relative 'corpus'
require_relative 'haiku'

class Poet < Sinatra::Base

  @@data_dir = File.expand_path(File.dirname(__FILE__) + '/../data/')

  @@syllable_dict = SyllableDictionary.new
  @@syllable_dict.init_from_csv_file("#{@@data_dir}/syllables.dict.csv")
  @@stopword_dict = Dictionary.new
  @@stopword_dict.init_from_csv_file("#{@@data_dir}/stopwords.dict.csv")

  @@corpora = Hash.new

  # corpora
  #
  # Class-level accessor to the cache of corpora for unit testing.
  #
  def self.corpora
    @@corpora
  end

  # syllable_dict
  #
  # Class-level accessor to the syllable dictionary for unit testing.
  #
  def self.syllable_dict
    @@syllable_dict
  end

  # Returns a list of corpora
  #
  get '/corpora' do
    if request.accept?('application/json')
      content_type 'application/json'
      [200, JSON.pretty_generate(get_corpora) + "\n"]
    else
      content_type 'text/plain'
      [200, get_corpora.join(' ') + "\n"]
    end
  end

  # Returns the desired corpus
  #
  get '/corpus/:corpusname' do |corpusname|
    begin
      corpus = get_corpus(corpusname)
    rescue
      return [404, "Corpus '#{corpusname}' does not exist.\n"]
    end

    if request.accept?('application/json')
      content_type 'application/json'
      [200, JSON.pretty_generate(corpus.to_hash) + "\n"]
    else
      content_type 'text/plain'
      [200, corpus.to_s + "\n"]
    end
  end

  # Generates one or more haikus using the specified corpus as a model
  #
  # Query parameters
  #   nresults  (integer) The number of poems to generate, default = '1'
  #   debug     (boolean) Append debugging information to the generated poem(s), default = 'false'
  #
  get '/haiku/:corpusname' do |corpusname|
    content_type 'text/plain'

    begin
      corpus = get_corpus(corpusname)
    rescue
      return [404, "Corpus '#{corpusname}' does not exist.\n"]
    end

    haiku = Haiku.new(corpus, @@syllable_dict)
    npoems = [(params[:nresults] || 1).to_i, 1].max
    debug = (params[:debug] || 'false').downcase == 'true'
    poems = Array.new(npoems)
    (0..npoems -1).each do |i|
      poems[i] = haiku.compose({:debug => debug})
    end

    if request.accept?('application/json')
      content_type 'application/json'
      poems.each_index { |i| poems[i] = poems[i].split("\n") }
      [200, JSON.pretty_generate(poems) + "\n"]
    else
      content_type 'text/plain'
      [200, poems.join("\n\n") + "\n"]
    end
  end

  # Returns true if the specified String is in the list of stopwords, otherwise false
  #
  get '/stopword/:word' do |word|
    result = @@stopword_dict.include?(word)

    if request.accept?('application/json')
      content_type 'application/json'
      [200, JSON.pretty_generate(Hash[word, result]) + "\n"]
    else
      content_type 'text/plain'
      [200, "#{result.to_s}\n"]
    end
  end

  # Estimates the number of syllables in the String
  #
  get '/syllables/:word' do |word|
    syllables = @@syllable_dict.count(word)

    if request.accept?('application/json')
      content_type 'application/json'
      [200, JSON.pretty_generate(Hash[word, syllables]) + "\n"]
    else
      content_type 'text/plain'
      [200, "#{syllables}\n"]
    end
  end

private

  # get_corpora
  #
  # Returns a list of corpora in the /data directory
  #
  def get_corpora
    names = []
    Dir["#{@@data_dir}/*.txt"].each { |file| names << file.split('/').last.chomp('.txt') }
    names
  end

  # get_corpus
  #
  # Generates and caches the desired corpus
  # TODO: Add a configuration option for the maximum ngram length?
  #
  def get_corpus(corpusname)
    if @@corpora.has_key?(corpusname)
      @@corpora[corpusname]
    else
      corpus = get_corpus_text(corpusname)
      @@corpora[corpusname] = Corpus.new(corpus, @@stopword_dict, {:maxn => 6})
    end
  end

  # get_corpus_text
  #
  # Gets the raw text from a corpus file
  #
  def get_corpus_text(filename)
    File.open("#{@@data_dir}/#{filename}.txt", 'r') do |file|
      file.read
    end
  end
end
