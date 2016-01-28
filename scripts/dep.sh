#!/bin/bash
#
# Setup the the box. This runs as root
#
#

# update package infos and upgrade all currently installed
apt-get -y update && apt-get -y upgrade

# install basic tools
apt-get -y install curl git apt-transport-https wget
apt-get -y install xterm vim htop multitail sysstat nmap tcpdump python-dev

apt-get -y install apt-file
apt-file update
apt-get -y install software-properties-common

apt-get -y update && apt-get -y upgrade

apt-get -y install libpam0g-dev libjpeg8-dev
apt-get -y install libssl-dev libffi-dev
# python-lxml requirements
apt-get install libxml2-dev libxslt-dev python-dev

# set python default encoding utf-8
sed -i "1s/^/import sys \nsys.setdefaultencoding('utf-8') \n /" /usr/lib/python2.7/sitecustomize.py

# Riak Installation

# file limits and some recommended tunings
echo 'ulimit -n 65536' >> /etc/default/riak
echo "session    required   pam_limits.so" >> /etc/pam.d/common-session
echo "session    required   pam_limits.so" >> /etc/pam.d/common-session-noninteractive
sed -i '$i\*              soft     nofile          65536\n\*              hard     nofile          65536'  /etc/security/limits.conf

# change linux boot options for riak performance
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="elevator=noop /' /etc/default/grub
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="clocksource=hpet /' /etc/default/grub
update-grub


# java install for solr
apt-add-repository ppa:webupd8team/java -y && apt-get update
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
apt-get install -y oracle-java8-installer

# zetaops riak package
curl -s https://packagecloud.io/install/repositories/zetaops/riak/script.deb.sh |sudo bash
apt-get install riak=2.1.1-1

# service stop and wait
service riak stop
sleep 10

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


# Redis Installation
apt-get install -y redis-server
sed -i "s/bind 127.0.0.1/bind 0.0.0.0/" /etc/redis/redis.conf

# Zato Installation
curl -s https://zato.io/repo/zato-0CBD7F72.pgp.asc | sudo apt-key add -
apt-add-repository https://zato.io/repo/stable/2.0/ubuntu
apt-get update
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

apt-get install -y virtualenvwrapper

mkdir /app
/usr/sbin/useradd --home-dir /app --shell /bin/bash --comment 'ulakbus operations' ulakbus
chown ulakbus:ulakbus /app -Rf

#Add ulakbus user to sudoers
adduser ulakbus sudo

sudo su - ulakbus sh -c "
cd ~

#environment variables specific to all libs
mkdir env-vars
cd env-vars
wget https://raw.githubusercontent.com/zetaops/ulakbus-development-box/master/scripts/env-vars/ulakbus_postactivate
wget https://raw.githubusercontent.com/zetaops/ulakbus-development-box/master/scripts/env-vars/pyoko_postactivate
wget https://raw.githubusercontent.com/zetaops/ulakbus-development-box/master/scripts/env-vars/zengine_postactivate

cd ~
#ulakbus virtualenv
virtualenv --no-site-packages ulakbusenv
cat ~/env-vars/ulakbus_postactivate >> ~/ulakbusenv/bin/activate

#pyoko virtualenv
virtualenv --no-site-packages pyokoenv
cat ~/env-vars/pyoko_postactivate >> ~/pyokoenv/bin/activate

#zengine virtualenv
virtualenv --no-site-packages zengineenv
cat ~/env-vars/zengine_postactivate >> ~/zengineenv/bin/activate

# clone pyoko from github
git clone https://github.com/zetaops/pyoko.git

# clone zengine from github
git clone https://github.com/zetaops/zengine.git

# clone ulakbus from github
git clone https://github.com/zetaops/ulakbus.git

# clone faker from github
git clone https://github.com/zetaops/faker.git

#activate ulakbusenv
source ~/ulakbusenv/bin/activate

pip install --upgrade pip
pip install ipython

cd ~/ulakbus
pip install -r requirements/requirements.txt



pip uninstall Pyoko		
pip uninstall pyoko		
pip uninstall zengine		
		
rm -rf ~/ulakbusenv/lib/python2.7/site-packages/Pyoko*		
rm -rf ~/ulakbusenv/lib/python2.7/site-packages/pyoko*		
rm -rf ~/ulakbusenv/lib/python2.7/site-packages/zengine*		

deactivate


#activate pyokoenv
source ~/pyokoenv/bin/activate

pip install --upgrade pip
pip install ipython

cd ~/pyoko
pip install -r requirements/default.txt

deactivate


#activate zengineenv
source ~/zengineenv/bin/activate

pip install --upgrade pip
pip install ipython

cd ~/zengine
pip install -r requirements/default.txt

pip uninstall Pyoko

rm -rf ~/zengineenv/lib/python2.7/site-packages/Pyoko*

deactivate

# Copy libraries: pyoko, ulakbus, zengine to ulakbusenv
ln -s ~/pyoko/pyoko      ~/ulakbusenv/lib/python2.7/site-packages
ln -s ~/ulakbus/ulakbus  ~/ulakbusenv/lib/python2.7/site-packages
ln -s ~/zengine/zengine  ~/ulakbusenv/lib/python2.7/site-packages
ln -s ~/ulakbus/tests    ~/ulakbusenv/lib/python2.7/site-packages
ln -s ~/faker/faker      ~/ulakbusenv/lib/python2.7/site-packages

# Necessary to use riak from zato user
touch ~/ulakbusenv/lib/python2.7/site-packages/google/__init__.py

# Copy libraries: pyoko, zengine to zengineenv
ln -s ~/pyoko/pyoko       ~/zengineenv/lib/python2.7/site-packages
ln -s ~/zengine/zengine   ~/zengineenv/lib/python2.7/site-packages
ln -s ~/zengine/tests     ~/zengineenv/lib/python2.7/site-packages

# Copy libraries: pyoko to pyokoenv
ln -s ~/pyoko/pyoko   ~/pyokoenv/lib/python2.7/site-packages
ln -s ~/pyoko/tests   ~/pyokoenv/lib/python2.7/site-packages
# end
"
# Create symbolic links for all dependecies and pyoko, zengine, ulakbus for Zato
# Since zato installations based on version numbers, I used wildcards while creating symbolic links
#
sudo su - zato sh -c "
ln -s /app/pyoko/pyoko                                                 /opt/zato/2.*.*/zato_extra_paths/
ln -s /app/zengine/zengine                                             /opt/zato/2.*.*/zato_extra_paths/
ln -s /app/ulakbus/ulakbus                                             /opt/zato/2.*.*/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/riak                 /opt/zato/2.*.*/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/riak_pb              /opt/zato/2.*.*/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/redis                /opt/zato/2.*.*/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/SpiffWorkflow        /opt/zato/2.*.*/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/werkzeug             /opt/zato/2.*.*/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/lazy_object_proxy    /opt/zato/2.*.*/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/falcon               /opt/zato/2.*.*/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/beaker               /opt/zato/2.*.*/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/passlib              /opt/zato/2.*.*/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/google               /opt/zato/2.*.*/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/enum                 /opt/zato/2.*.*/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/celery               /opt/zato/2.*.*/zato_extra_paths/
"

# Create symbolic links for zato project to start them at login

ln -s /opt/zato/ulakbus/load-balancer /etc/zato/components-enabled/ulakbus.load-balancer
ln -s /opt/zato/ulakbus/server1 /etc/zato/components-enabled/ulakbus.server1
ln -s /opt/zato/ulakbus/web-admin /etc/zato/components-enabled/ulakbus.web-admin

# Start zato service
service zato start

service riak start
sleep 30

riak-admin bucket-type create pyoko_models '{"props":{"last_write_wins":true, "allow_mult":false, "n_val":1}}'
riak-admin bucket-type create zengine_models '{"props":{"last_write_wins":true, "allow_mult":false, "n_val":1}}'
riak-admin bucket-type create models '{"props":{"last_write_wins":true, "allow_mult":false, "n_val":1}}'
riak-admin bucket-type create catalog '{"props":{"last_write_wins":true, "dvv_enabled":false, "allow_mult":false, "n_val": 1}}'

riak-admin bucket-type activate pyoko_models
riak-admin bucket-type activate zengine_models
riak-admin bucket-type activate models
riak-admin bucket-type activate catalog

# Initial migration of ulakbus models and load fixtures
sudo su - ulakbus sh -c "
cd ~
source ~/ulakbusenv/bin/activate
python ~/ulakbus/ulakbus/manage.py migrate --model all
python ~/ulakbus/ulakbus/manage.py load_fixture --path ~/ulakbus/ulakbus/fixtures/
deactivate
"

apt-get -y autoremove
apt-get clean
rm -rf /var/lib/apt/lists/*
