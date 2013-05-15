#!/bin/bash

ENV=${1:-development}

echo "------> Bootstrapping master for environment $ENV"

__apt_get_noinput() {
    apt-get install -y -o DPkg::Options::=--force-confold $@
}

apt-get update
__apt_get_noinput python-software-properties curl debconf-utils
apt-get update

# We're using the saltstack canonical bootstrap method here to stay with the
# latest open-source efforts
#
# Eventually, we can come to settle down on our own way of bootstrapping
\curl -L http://bootstrap.saltstack.org | sudo sh -s -- -M stable

# Set the hostname
echo """
127.0.0.1       localhost
127.0.1.1       saltmaster
""" > /etc/hosts
echo "saltmaster" > /etc/hostname
hostname `cat /etc/hostname`
mkdir -p /etc/salt

echo """
run_as: root

open_mode: False
auto_accept: False

worker_threads: 5

file_roots:
  base:
    - /srv/salt/states
  development:
    - /srv/salt/states/env/development
  staging:
    - /srv/salt/states/env/staging
  production:
    - /srv/salt/states/env/production

pillar_roots:
  base:
    - /srv/salt/pillar
  development:
    - /srv/salt/pillar/development
  staging:
    - /srv/salt/pillar/staging
  production:
    - /srv/salt/pillar/production

peer:
  .*:
    - network.ip_addrs
    - grains.*

master: 127.0.0.1
grains:
  roles: 
    - master
  environment: $ENV
""" > /etc/salt/master


echo """
### This is controlled by the hosts file
master: saltmaster

id: saltmaster

grains:
  environment: $ENV
  roles: 
    - master

log_file: /var/log/salt/minion
log_level: debug
log_level_logfile: garbage
""" > /etc/salt/minion

# sudo restart salt-master

sudo service salt-minion restart
sleep 10
sudo salt-key -a saltmaster
sudo salt-key -a `hostname`

sudo restart salt-master