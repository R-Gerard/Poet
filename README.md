Poet
====
Procedurally generated poetry using statistical models generated from source material (public domain sonnets, short stories, novels, etc.).
Includes a simple web service implemented in Sinatra for greater versatility.


Installation
============
Quickstart: install VirtualBox and Vagrant, then run `vagrant up` from the command line.

Refer to bootstrap.sh for details about installation.

To start the service, run `rackup -p 8080 -D`
To stop the service, run `pkill -9 -f rackup`

Get VirtualBox here: https://www.virtualbox.org/
Get Vagrant here: http://www.vagrantup.com/


APIs
====

| HTTP Method | Route | Query Parameters | Description |
| ----------- | ----- | ---------------- | ----------- |
| GET | /corpora | N/A | Returns a list of corpora included with Poet. |
| GET | /corpus/`:corpusname` | N/A | Returns the corpus as either raw text or as a statistical model in JSON format. |
| GET | /haiku/`:corpusname` | `nresults` (integer, default = '1') <br/>`debug` (boolean, default = 'false') | Generates one or more haikus from a desired corpus. |
| GET | /stopword/`:word` | N/A | Returns 'true' or 'false' if the word is considered a stopword. |
| GET | /syllables/`:word` | N/A | Returns the number of syllables estimated for the word. |


Example Usage
-------------
Get a list of corpora available:

    curl -sS "http://localhost:8080/corpora"

Get the statistical model for The Fortress Unvanquishable:

    curl -sS -H "Accept: application/json" "http://localhost:8080/corpus/the_fortress_unvanquishable"

Get the plain text source for The Fortress Unvanquishable:

    curl -sS -H "Accept: text/plain" "http://localhost:8080/corpus/the_fortress_unvanquishable"

Generate 100 haikus in plain text using The Fortress Unvanquishable as the source material in the file 'output_plain.txt' and with debugging notes in the file 'output_debug.txt':

    curl -sS -H "Accept: text/plain" "http://localhost:8080/haiku/the_fortress_unvanquishable?nresults=100&debug=true" > output_debug.txt ; sed 's/ ([^)]*)//g' output_debug.txt > output_plain.txt


Adding New Corpora
==================
Drop a plain text file with the extension .txt in the /data directory; you should see your file by calling `GET /corpora`.
The statistical model will be computed and cached in memory upon the first request for that corpus.
'#' characters at the start of lines indicate comments (copyright notices, chapter titles, etc.).
