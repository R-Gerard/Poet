#!/bin/bash
#
# Simple install script. Assumes script is ran from root directory of the project.
#

if [ "$(whoami)" != "root" ]; then
  echo Installation must be as root
  exit 1
fi

# Allow TCP connections on port 8080
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -F

# Install RVM, Ruby, Rubygems, Bundler, and required gems
yum -y remove ruby

curl -L https://get.rvm.io | bash -s stable --ruby
source /usr/local/rvm/scripts/rvm
source /etc/profile.d/rvm.sh

bundle install

# The service is now ready to use by running 'rackup' from the root directory of the project

if [ "$1" == "--norackup" ]; then
  # Copy files to /var/poet so the service can be controlled using init.d
  rm -f /etc/init.d/poet
  cp bin/poet /etc/init.d/
  chmod 755 /etc/init.d/poet
  rm -rf /var/poet
  mkdir /var/poet
  cp -r data /var/poet/
  cp -r lib /var/poet/
fi
