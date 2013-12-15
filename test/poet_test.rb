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

ENV['RACK_ENV'] = 'test'
require 'test/unit'
require 'rack/test'
require_relative '../lib/poet'

class PoetTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Poet.new
  end

  def validate_response_200_plaintext(response)
    assert response.ok?, 'Response was not 200 OK'
    assert response.headers['Content-Type'].include?('text/plain'), 'Response has wrong content type'
  end

  def validate_response_200_json(response)
    assert response.ok?, 'Response was not 200 OK'
    assert response.headers['Content-Type'].include?('application/json'), 'Response has wrong content type'
  end

  def validate_haikus_plaintext(haikus, nresults)
    assert_equal 4 * nresults -1, haikus.lines.count, "Poem contains the wrong number of lines for #{nresults} haiku(s)"
    assert_equal 17 * nresults, Poet.syllable_dict.count(haikus), "Poem contains the wrong number of syllables for #{nresults} haiku(s)"
  end

  def validate_haikus_json(haikus, nresults=1)
    assert_equal nresults, haikus.size, 'Response contains wrong number of poems'

    haikus.each_index do |i|
      assert_equal 3, haikus[i].length, "Poem #{i} contains the wrong number of lines for a haiku"
      assert_equal 17, Poet.syllable_dict.count(haikus[i].join("\n")), "Poem #{i} contains the wrong number of syllables for a haiku"
    end
  end

  def test_get_corpora_plaintext
    get '/corpora', nil, {'HTTP_ACCEPT' => 'text/plain'}

    validate_response_200_plaintext(last_response)

    ['fungi_from_yuggoth', 'the_fortress_unvanquishable', 'the_raven'].each do |corpus|
      assert last_response.body.include?(corpus), "Response is missing corpus '#{corpus}'"
    end
  end

  def test_get_corpora_json
    get '/corpora', nil, {'HTTP_ACCEPT' => 'application/json'}

    validate_response_200_json(last_response)
    response = JSON.parse(last_response.body)

    ['fungi_from_yuggoth', 'the_fortress_unvanquishable', 'the_raven'].each do |corpus|
      assert response.include?('fungi_from_yuggoth'), "Response is missing corpus '#{corpus}'"
    end
  end

  def test_get_corpus_plaintext
    get '/corpus/fungi_from_yuggoth', nil, {'HTTP_ACCEPT' => 'text/plain'}

    validate_response_200_plaintext(last_response)

    assert last_response.body.include?('# Fungi from Yuggoth'), 'Corpus rawtext is missing title comment'
    assert last_response.body.include?('# By H.P. Lovecraft'), 'Corpus rawtext is missing author comment'
    assert last_response.body.include?('The place was dark and dusty and half-lost'), 'Corpus rawtext is missing first line'
    assert last_response.body.include?('From the fixt mass whose sides the ages are.'), 'Corpus rawtext is missing last line'

    assert Poet.corpora.include?('fungi_from_yuggoth'), 'Corpus was not cached'
    assert Poet.corpora['fungi_from_yuggoth'].is_a?(Corpus), 'Cached object is not the right type'
  end

  def test_get_corpus_json
    get '/corpus/fungi_from_yuggoth', nil, {'HTTP_ACCEPT' => 'application/json'}

    validate_response_200_json(last_response)
    response = JSON.parse(last_response.body)

    assert_equal 4118, response['wordcount'], 'Corpus has wrong wordlength'
    assert response['topic_words'].include?('old'), 'Corpus is missing expected topic word'
    assert_equal 77, response['unigrams']['in'], "unigram frequency count for 'in' is incorrect"
    assert_equal 10, response['bigrams']['in']['the'], "bigram frequency count for 'in the' is incorrect"
    assert_equal 2, response['trigrams']['in the']['night'], "trigram frequency count for 'in the night' is incorrect"

    assert Poet.corpora.include?('fungi_from_yuggoth'), 'Corpus was not cached'
    assert Poet.corpora['fungi_from_yuggoth'].is_a?(Corpus), 'Cached object is not the right type'
  end

  def test_get_corpus_404_plaintext
    get '/corpus/bogus', nil, {'HTTP_ACCEPT' => 'text/plain'}

    assert_equal 404, last_response.status, 'Response was not 404 Not Found'
  end

  def test_get_corpus_404_json
    get '/corpus/bogus', nil, {'HTTP_ACCEPT' => 'application/json'}

    assert_equal 404, last_response.status, 'Response was not 404 Not Found'
  end

  def test_haiku_default_plaintext
    get '/haiku/fungi_from_yuggoth', nil, {'HTTP_ACCEPT' => 'text/plain'}

    validate_response_200_plaintext(last_response)
    validate_haikus_plaintext(last_response.body, 1)

    assert !last_response.body.include?('('), 'Haiku contains debugging information'
    assert !last_response.body.include?(')'), 'Haiku contains debugging information'
  end

  def test_haiku_default_json
    get '/haiku/fungi_from_yuggoth', nil, {'HTTP_ACCEPT' => 'application/json'}

    validate_response_200_json(last_response)
    response = JSON.parse(last_response.body)

    validate_haikus_json(response, 1)
    assert !response[0][0].include?('('), 'Haiku contains debugging information'
    assert !response[0][0].include?(')'), 'Haiku contains debugging information'
  end

  def test_haiku_single_plaintext
    get '/haiku/fungi_from_yuggoth?nresults=1', nil, {'HTTP_ACCEPT' => 'text/plain'}

    validate_response_200_plaintext(last_response)
    validate_haikus_plaintext(last_response.body, 1)
  end

  def test_haiku_single_json
    get '/haiku/fungi_from_yuggoth?nresults=1', nil, {'HTTP_ACCEPT' => 'application/json'}

    validate_response_200_json(last_response)
    response = JSON.parse(last_response.body)

    validate_haikus_json(response, 1)
  end

  def test_haiku_multiple_plaintext
    nresults = rand(2..99)
    get "/haiku/fungi_from_yuggoth?nresults=#{nresults}", nil, {'HTTP_ACCEPT' => 'text/plain'}

    validate_response_200_plaintext(last_response)
    validate_haikus_plaintext(last_response.body, nresults)
  end

  def test_haiku_multiple_json
    nresults = rand(2..99)
    get "/haiku/fungi_from_yuggoth?nresults=#{nresults}", nil, {'HTTP_ACCEPT' => 'application/json'}

    validate_response_200_json(last_response)
    response = JSON.parse(last_response.body)

    validate_haikus_json(response, nresults)
  end

  def test_haiku_negative_plaintext
    nresults = rand(-1..-99)
    get "/haiku/fungi_from_yuggoth?nresults=#{nresults}", nil, {'HTTP_ACCEPT' => 'text/plain'}

    validate_response_200_plaintext(last_response)
    validate_haikus_plaintext(last_response.body, 1)
  end

  def test_haiku_negative_json
    nresults = rand(-1..-99)
    get "/haiku/fungi_from_yuggoth?nresults=#{nresults}", nil, {'HTTP_ACCEPT' => 'application/json'}

    validate_response_200_json(last_response)
    response = JSON.parse(last_response.body)

    validate_haikus_json(response, 1)
  end

  def test_haiku_zero_plaintext
    get '/haiku/fungi_from_yuggoth?nresults=0', nil, {'HTTP_ACCEPT' => 'text/plain'}

    validate_response_200_plaintext(last_response)
    validate_haikus_plaintext(last_response.body, 1)
  end

  def test_haiku_zero_json
    get '/haiku/fungi_from_yuggoth?nresults=0', nil, {'HTTP_ACCEPT' => 'application/json'}

    validate_response_200_json(last_response)
    response = JSON.parse(last_response.body)

    validate_haikus_json(response, 1)
  end

  def test_haiku_nonint_plaintext
    get '/haiku/fungi_from_yuggoth?nresults=random', nil, {'HTTP_ACCEPT' => 'text/plain'}

    validate_response_200_plaintext(last_response)
    validate_haikus_plaintext(last_response.body, 1)
  end

  def test_haiku_nonint_json
    get '/haiku/fungi_from_yuggoth?nresults=random', nil, {'HTTP_ACCEPT' => 'application/json'}

    validate_response_200_json(last_response)
    response = JSON.parse(last_response.body)

    validate_haikus_json(response, 1)
  end

  def test_haiku_debug_plaintext
    get '/haiku/fungi_from_yuggoth?debug=true', nil, {'HTTP_ACCEPT' => 'text/plain'}

    validate_response_200_plaintext(last_response)
    validate_haikus_plaintext(last_response.body, 1)

    # Leave the actual debug validation to haiku_test, just validate that the query parameter was respected
    assert last_response.body.include?('('), 'Haiku is missing debugging information'
    assert last_response.body.include?(')'), 'Haiku is missing debugging information'
  end

  def test_haiku_debug_json
    get '/haiku/fungi_from_yuggoth?debug=true', nil, {'HTTP_ACCEPT' => 'application/json'}

    validate_response_200_json(last_response)
    response = JSON.parse(last_response.body)

    validate_haikus_json(response, 1)

    # Leave the actual debug validation to haiku_test, just validate that the query parameter was respected
    assert response[0][0].include?('('), 'Haiku is missing debugging information'
    assert response[0][0].include?(')'), 'Haiku is missing debugging information'
  end

  def test_haiku_404_plaintext
    get '/haiku/bogus', nil, {'HTTP_ACCEPT' => 'text/plain'}

    assert_equal 404, last_response.status, 'Response was not 404 Not Found'
  end

  def test_haiku_404_json
    get '/haiku/bogus', nil, {'HTTP_ACCEPT' => 'application/json'}

    assert_equal 404, last_response.status, 'Response was not 404 Not Found'
  end

  def test_stopword_true_plaintext
    get '/stopword/the', nil, {'HTTP_ACCEPT' => 'text/plain'}

    validate_response_200_plaintext(last_response)
    assert_equal "true\n", last_response.body, 'Response body is incorrect'
  end

  def test_stopword_true_json
    get '/stopword/the', nil, {'HTTP_ACCEPT' => 'application/json'}

    validate_response_200_json(last_response)
    response = JSON.parse(last_response.body)

    assert response.has_key?('the'), 'Response is missing expected key'
    assert_equal true, response['the'], 'Response body is incorrect'
  end

  def test_stopword_false_plaintext
    get '/stopword/diabetes', nil, {'HTTP_ACCEPT' => 'text/plain'}

    validate_response_200_plaintext(last_response)
    assert_equal "false\n", last_response.body, 'Response body is incorrect'
  end

  def test_stopword_false_json
    get '/stopword/diabetes', nil, {'HTTP_ACCEPT' => 'application/json'}

    validate_response_200_json(last_response)
    response = JSON.parse(last_response.body)

    assert response.has_key?('diabetes'), 'Response is missing expected key'
    assert_equal false, response['diabetes'], 'Response body is incorrect'
  end

  def test_syllables_single_plaintext
    get '/syllables/diabetes', nil, {'HTTP_ACCEPT' => 'text/plain'}

    validate_response_200_plaintext(last_response)
    assert_equal "4\n", last_response.body, 'Response body is incorrect'
  end

  def test_syllables_single_json
    get '/syllables/diabetes', nil, {'HTTP_ACCEPT' => 'application/json'}

    validate_response_200_json(last_response)
    response = JSON.parse(last_response.body)

    assert response.has_key?('diabetes'), 'Response is missing expected key'
    assert_equal 4, response['diabetes'], 'Response body is incorrect'
  end

  def test_syllables_mixedstring_plaintext
    haiku = "Poets don't have a\ndevil-may-care attitude.\n...Inconceivable!"

    get "/syllables/#{URI.escape(haiku)}", nil, {'HTTP_ACCEPT' => 'text/plain'}

    validate_response_200_plaintext(last_response)
    assert_equal "17\n", last_response.body, 'Response body is incorrect'
  end

  def test_syllables_mixedstring_json
    haiku = "Poets don't have a\ndevil-may-care attitude.\n...Inconceivable!"

    get "/syllables/#{URI.escape(haiku)}", nil, {'HTTP_ACCEPT' => 'application/json'}

    validate_response_200_json(last_response)
    response = JSON.parse(last_response.body)

    assert response.has_key?(haiku), 'Response is missing expected key'
    assert_equal 17, response[haiku], 'Response body is incorrect'
  end
end
