#!/bin/bash

use_rackup=1

echo --------------------------------------------------
echo BEGIN BOOTSTRAP.SH
echo --------------------------------------------------

echo "nameserver 192.168.1.1" > /etc/resolv.conf

cd /vagrant
if [ $use_rackup ]; then
  ./install.sh --rackup
else
  ./install.sh --norackup
fi

source /usr/local/rvm/scripts/rvm
source /etc/profile.d/rvm.sh

echo --------------------------------------------------
echo VERIFY INSTALL
echo --------------------------------------------------

iptables -L -v

rvm list
ruby -v
which ruby
gem -v
which gem
bundle -v
which bundle
rackup -v
which rackup
gem list --local

echo --------------------------------------------------
echo UNIT TESTS
echo --------------------------------------------------

# TODO: Put these in a test suite
ruby ./test/syllable_dictionary_test.rb
ruby ./test/corpus_test.rb
ruby ./test/haiku_test.rb
ruby ./test/poet_test.rb

echo --------------------------------------------------
echo START SERVICE
echo --------------------------------------------------

if [ $use_rackup ]; then
  rackup -p 8080 -D
  echo type 'pkill -9 -f rackup' to stop service
else
  service poet restart
fi

echo --------------------------------------------------
echo END BOOTSTRAP.SH
echo --------------------------------------------------
