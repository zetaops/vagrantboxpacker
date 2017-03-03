#!/bin/bash
#
# Setup the the box. This runs as root
#
#

# Required for build of lxml
dd if=/dev/zero of=/swapfile bs=1024 count=524288
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile


# Rabbitmq Adding Repository
echo 'deb http://www.rabbitmq.com/debian/ testing main' |
        sudo tee /etc/apt/sources.list.d/rabbitmq.list

wget -O- https://www.rabbitmq.com/rabbitmq-signing-key-public.asc |
        sudo apt-key add -

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C2518248EEA14886
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6B73A36E6026DFCA

# update package infos and upgrade all currently installed
apt-get -y update && apt-get -y upgrade

# Rabbitmq Server Installation
apt-get -y install rabbitmq-server

# install basic tools
apt-get -y install curl git apt-transport-https wget
apt-get -y install xterm vim htop multitail sysstat nmap tcpdump

apt-get -y install apt-file
apt-file update
apt-get -y install software-properties-common

apt-get -y update && apt-get -y upgrade

# python, lxml, reportlab requirements
apt-get -y install libpam0g-dev libjpeg8-dev libpng-dev zlib1g-dev libxml2-dev libxslt1-dev
apt-get -y install libssl-dev libffi-dev
apt-get -y install python-dev python-lxml virtualenvwrapper


# set python default encoding utf-8
sed -i "1s/^/import sys \nsys.setdefaultencoding('utf-8') \n /" /usr/lib/python2.7/sitecustomize.py


######## Riak Installation ############
# Riak Installation and Configuration
# Install java for solr, riak package from basho official packagecloud repository
# configure system for riak
# configure riak installation

# java install for solr
apt-add-repository ppa:webupd8team/java -y && apt-get -y update
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
apt-get install -y oracle-java8-installer

# riak package
curl -s https://packagecloud.io/install/repositories/basho/riak/script.deb.sh | sudo bash
sudo apt-get -y install riak=2.2.0-1

# service stop and wait
service riak stop
sleep 10

# file limits and some recommended tunings
echo 'ulimit -n 65536' >> /etc/default/riak
echo "session    required   pam_limits.so" >> /etc/pam.d/common-session
echo "session    required   pam_limits.so" >> /etc/pam.d/common-session-noninteractive
sed -i '$i\*              soft     nofile          65536\n\*              hard     nofile          65536'  /etc/security/limits.conf

# change linux boot options for riak performance
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="elevator=noop /' /etc/default/grub
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="clocksource=hpet /' /etc/default/grub
update-grub

sed -i "s/search = off/search = on/" /etc/riak/riak.conf
sed -i "s/anti_entropy = active/anti_entropy = passive/" /etc/riak/riak.conf
sed -i "s/storage_backend = bitcask/storage_backend = multi/" /etc/riak/riak.conf
sed -i "s/search.solr.start_timeout = 30s/search.solr.start_timeout = 120s/" /etc/riak/riak.conf
sed -i "s/leveldb.maximum_memory.percent = 70/leveldb.maximum_memory.percent = 30/" /etc/riak/riak.conf
sed -i "s/listener.http.internal = 127.0.0.1:8098/listener.http.internal = 0.0.0.0:8098/" /etc/riak/riak.conf
sed -i "s/listener.protobuf.internal = 0.0.0.0:8087/listener.protobuf.internal = 0.0.0.0:8087/" /etc/riak/riak.conf

echo "multi_backend.bitcask_mult.storage_backend = bitcask
multi_backend.bitcask_mult.bitcask.data_root = /var/lib/riak/bitcask_mult
multi_backend.leveldb_mult.storage_backend = leveldb
multi_backend.leveldb_mult.leveldb.data_root = /var/lib/riak/leveldb_mult
multi_backend.default = bitcask_mult
search.solr.jvm_options = -d64 -Xms512m -Xmx512m -XX:+UseStringCache -XX:+UseCompressedOops" >> /etc/riak/riak.conf
######## Riak Installation ############


######## Riak Installation ############
# Install Redis
# bind it 0.0.0.0 to access from host machine

apt-get install -y redis-server
sed -i "s/bind 127.0.0.1/bind 0.0.0.0/" /etc/redis/redis.conf
######## Riak Installation ############


######## Zato Installation ############
# Install Zato Quickstart Cluster for 1 node
# Create a ulakbus cluster, changes its webadmin password
# Create symbolic links of python packages of ulakbus and related libs

curl -s https://zato.io/repo/zato-0CBD7F72.pgp.asc | sudo apt-key add -
apt-add-repository https://zato.io/repo/stable/2.0/ubuntu -y
apt-get -y update
apt-get install -y zato

sudo su - zato sh -c "

wget https://raw.githubusercontent.com/zetaops/ulakbus-development-box/master/scripts/env-vars/zato_environment_variables
cat ~/zato_environment_variables >> ~/.profile
source ~/.profile

mkdir ~/ulakbus;

# Create a new zato project named ulakbus
zato quickstart create ~/ulakbus sqlite localhost 6379 --kvdb_password='' --servers 1 --verbose;

# Change password of zato admin to new one.(Password = ulakbus)
echo 'command=update_password
path=/opt/zato/ulakbus/web-admin
store_config=True
username=admin
password=ulakbus' > ~/ulakbus/zatopw.conf

zato from-config ~/ulakbus/zatopw.conf
"

# Create symbolic links for zato project to start them at login
ln -s /opt/zato/ulakbus/load-balancer /etc/zato/components-enabled/ulakbus.load-balancer
ln -s /opt/zato/ulakbus/server1 /etc/zato/components-enabled/ulakbus.server1
ln -s /opt/zato/ulakbus/web-admin /etc/zato/components-enabled/ulakbus.web-admin
######## Zato Installation ############


######## Ulakbus Installation ############
# creates ulabus user
# creates an virtual python environment
# and install ulakbus' requirements

# ulakbus user
mkdir /app
/usr/sbin/useradd --home-dir /app --shell /bin/bash --comment 'ulakbus operations' ulakbus
chown ulakbus:ulakbus /app -Rf

# make ulakbus sudoer
adduser ulakbus sudo

sudo su - ulakbus sh -c "
# go home
cd ~

# ulakbus virtualenv
virtualenv --no-site-packages ulakbusenv

wget https://raw.githubusercontent.com/zetaops/ulakbus-development-box/master/scripts/env-vars/ulakbus_postactivate
cat ~/ulakbus_postactivate >> ~/ulakbusenv/bin/activate

# log dir
mkdir /app/logs/


# clone pyoko from github
git clone https://github.com/zetaops/pyoko.git

# clone zengine from github
git clone https://github.com/zetaops/zengine.git

# clone ulakbus from github
git clone https://github.com/zetaops/ulakbus.git


# activate ulakbusenv
source ~/ulakbusenv/bin/activate

pip install --upgrade pip
pip install ipython

cd ~/ulakbus
pip install -r requirements/develop.txt


deactivate

# Copy libraries: pyoko, ulakbus, zengine to ulakbusenv
ln -s ~/pyoko/pyoko      ~/ulakbusenv/lib/python2.7/site-packages
ln -s ~/ulakbus/ulakbus  ~/ulakbusenv/lib/python2.7/site-packages
ln -s ~/zengine/zengine  ~/ulakbusenv/lib/python2.7/site-packages
ln -s ~/ulakbus/tests    ~/ulakbusenv/lib/python2.7/site-packages
ln -s ~/faker/faker      ~/ulakbusenv/lib/python2.7/site-packages

# Necessary to use riak from zato user
touch ~/ulakbusenv/lib/python2.7/site-packages/google/__init__.py"

# Create symbolic links for all dependecies and pyoko, zengine, ulakbus for Zato
# Since zato installations based on version numbers, I used wildcards while creating symbolic links
#
sudo su - zato sh -c "
ln -s /app/pyoko/pyoko                                                 /opt/zato/current/zato_extra_paths/
ln -s /app/zengine/zengine                                             /opt/zato/current/zato_extra_paths/
ln -s /app/ulakbus/ulakbus                                             /opt/zato/current/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/riak                 /opt/zato/current/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/redis                /opt/zato/current/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/SpiffWorkflow        /opt/zato/current/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/werkzeug             /opt/zato/current/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/lazy_object_proxy    /opt/zato/current/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/falcon               /opt/zato/current/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/beaker               /opt/zato/current/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/beaker_extensions    /opt/zato/current/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/passlib              /opt/zato/current/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/google               /opt/zato/current/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/enum                 /opt/zato/current/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/celery               /opt/zato/current/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/funcsigs             /opt/zato/current/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/streamingxmlwriter   /opt/zato/current/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/babel                /opt/zato/current/zato_extra_paths/
"
######## Ulakbus Installation ############



######## Service Post Installation ############
# create riak bucket types
# activate buckets
#
# rabbitmq add virtualhost ulakbus
#
service riak start
sleep 30

riak-admin bucket-type create pyoko_models '{"props":{"last_write_wins":true, "dvv_enabled":false, "allow_mult":false, "n_val":1}}'
riak-admin bucket-type create zengine_models '{"props":{"last_write_wins":true, "dvv_enabled":false, "allow_mult":false, "n_val":1}}'
riak-admin bucket-type create models '{"props":{"last_write_wins":true, "dvv_enabled":false, "allow_mult":false, "n_val":1}}'
riak-admin bucket-type create catalog '{"props":{"last_write_wins":true, "dvv_enabled":false, "allow_mult":false, "n_val": 1}}'
riak-admin bucket-type create log_version '{"props": {"backend": "leveldb_mult"}}'


riak-admin bucket-type activate pyoko_models
riak-admin bucket-type activate zengine_models
riak-admin bucket-type activate models
riak-admin bucket-type activate catalog
riak-admin bucket-type activate log_version


# Rabbitmq Ulakbus Configuration
rabbitmqctl add_vhost ulakbus
rabbitmqctl add_user ulakbus 123
rabbitmqctl set_permissions -p ulakbus ulakbus ".*" ".*" ".*"
######## Service Post Installation ############

######## Initial migration of ulakbus models and load fixtures ############
#
sudo su - ulakbus sh -c "
cd ~
source ~/ulakbusenv/bin/activate
pip install lxml
python ~/ulakbus/ulakbus/manage.py migrate --model all
python ~/ulakbus/ulakbus/manage.py load_data --path ~/ulakbus/tests/fixtures/
sleep 2
python ~/ulakbus/ulakbus/manage.py load_diagrams
python ~/ulakbus/ulakbus/manage.py load_fixture --path ~/ulakbus/ulakbus/fixtures/
python ~/ulakbus/ulakbus/manage.py preparemq
python manage.py compile_translations
deactivate
"
######## Initial migration of ulakbus models and load fixtures ############

# Clean up
apt-get -y autoremove
apt-get clean
rm -rf /var/lib/apt/lists/*
