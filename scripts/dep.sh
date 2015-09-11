#!/bin/bash
#
# Setup the the box. This runs as root

apt-get -y update
apt-get -y install curl
apt-get -y install git
apt-get -y install apt-file
apt-file update
apt-get -y install software-properties-common

apt-get -y install vim htop multitail sysstat nmap tcpdump python-dev

apt-get -y update
apt-get -y upgrade

ulimit -n 65536
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

apt-add-repository ppa:webupd8team/java -y && apt-get update
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
apt-get install -y oracle-java8-installer

curl -s https://packagecloud.io/install/repositories/zetaops/riak/script.deb.sh |sudo bash
apt-get install riak=2.1.1-1

sed -i "s/search = off/search = on/" /etc/riak/riak.conf
sed -i "s/anti_entropy = active/anti_entropy = passive/" /etc/riak/riak.conf
sed -i "s/storage_backend = bitcask/storage_backend = multi/" /etc/riak/riak.conf

echo "multi_backend.bitcask_mult.storage_backend = bitcask
multi_backend.bitcask_mult.bitcask.data_root = /var/lib/riak/bitcask_mult

multi_backend.leveldb_mult.storage_backend = leveldb
multi_backend.leveldb_mult.leveldb.data_root = /var/lib/riak/leveldb_mult

multi_backend.default = bitcask_mult" >> /etc/riak/riak.conf

service riak restart

apt-get install -y libssl-dev
apt-get install -y libffi-dev


apt-get install -y redis-server

apt-get install -y  apt-transport-https
curl -s https://zato.io/repo/zato-0CBD7F72.pgp.asc | sudo apt-key add -
apt-add-repository https://zato.io/repo/stable/2.0/ubuntu
apt-get update
apt-get install -y zato

sudo su - zato sh -c "

https://raw.githubusercontent.com/dyrnade/vagrantboxpacker/backup/scripts/env-vars/zato_environment_variables
cat ~/zato_environment_variables >> ~/.profile
source ~/.profile

mkdir ~/ulakbus;

# Create a new zato project named ulakbus
zato quickstart create ~/ulakbus sqlite localhost 6379 --kvdb_password='' --verbose;

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

#ulakbus virtualenv
virtualenv --no-site-packages ulakbusenv
wget https://raw.githubusercontent.com/dyrnade/vagrantboxpacker/backup/scripts/env-vars/ulakbus_postactivate
cat ~/ulakbus_postactivate >> ~/ulakbusenv/bin/activate

#pyoko virtualenv
virtualenv --no-site-packages pyokoenv
wget https://raw.githubusercontent.com/dyrnade/vagrantboxpacker/backup/scripts/env-vars/pyoko_postactivate
cat ~/pyoko_postactivate >> ~/pyokoenv/bin/activate

#zengine virtualenv
virtualenv --no-site-packages zengineenv
wget https://raw.githubusercontent.com/dyrnade/vagrantboxpacker/backup/scripts/env-vars/zengine_postactivate
cat ~/zengine_postactivate >> ~/zengineenv/bin/activate

# clone pyoko from github
git clone https://github.com/zetaops/pyoko.git

# clone zengine from github
git clone https://github.com/zetaops/zengine.git

# clone ulakbus from github
git clone https://github.com/zetaops/ulakbus.git


#activate ulakbusenv
source ~/ulakbusenv/bin/activate

pip install --upgrade pip
pip install ipython

cd ~/ulakbus
pip install -r requirements.txt

pip uninstall Pyoko
pip uninstall zengine

rm -rf ~/ulakbusenv/lib/python2.7/site-packages/Pyoko*
rm -rf ~/ulakbusenv/lib/python2.7/site-packages/zengine*

deactivate


#activate pyokoenv
source ~/pyokoenv/bin/activate

pip install --upgrade pip
pip install ipython

cd ~/pyoko
pip install -r requirements.txt

deactivate


#activate zengineenv
source ~/zengineenv/bin/activate

pip install --upgrade pip
pip install ipython

cd ~/zengine
pip install -r requirements.txt

pip uninstall Pyoko

rm -rf ~/zengineenv/lib/python2.7/site-packages/Pyoko*

deactivate

# Copy libraries: pyoko, ulakbus, zengine to ulakbusenv
ln -s ~/pyoko/pyoko ~/ulakbusenv/lib/python2.7/site-packages
ln -s ~/ulakbus/ulakbus ~/ulakbusenv/lib/python2.7/site-packages
ln -s ~/zengine/zengine ~/ulakbusenv/lib/python2.7/site-packages
ln -s ~/ulakbus/tests ~/ulakbusenv/lib/python2.7/site-packages

# Necessary to use riak from zato user
touch ~/ulakbusenv/lib/python2.7/site-packages/google/__init__.py

# Copy libraries: pyoko, zengine to zengineenv
ln -s ~/pyoko/pyoko ~/zengineenv/lib/python2.7/site-packages
ln -s ~/zengine/zengine ~/zengineenv/lib/python2.7/site-packages
ln -s ~/zengine/tests ~/zengineenv/lib/python2.7/site-packages

# Copy libraries: pyoko to pyokoenv
ln -s ~/pyoko/pyoko ~/pyokoenv/lib/python2.7/site-packages
ln -s ~/pyoko/tests ~/pyokoenv/lib/python2.7/site-packages

"
# Create symbolic links for all dependecies and pyoko, zengine, ulakbus for Zato

sudo su - zato sh -c "
ln -s /app/pyoko/pyoko                                                                      /opt/zato/2.0.5/zato_extra_paths/
ln -s /app/zengine/zengine                                                                  /opt/zato/2.0.5/zato_extra_paths/
ln -s /app/ulakbus/ulakbus                                                                  /opt/zato/2.0.5/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/riak                               /opt/zato/2.0.5/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/riak_pb                         /opt/zato/2.0.5/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/redis                             /opt/zato/2.0.5/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/SpiffWorkflow             /opt/zato/2.0.5/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/werkzeug                       /opt/zato/2.0.5/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/lazy_object_proxy     /opt/zato/2.0.5/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/falcon                           /opt/zato/2.0.5/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/beaker                           /opt/zato/2.0.5/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/passlib                         /opt/zato/2.0.5/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/google                                    /opt/zato/2.0.5/zato_extra_paths/
ln -s /app/ulakbusenv/lib/python2.7/site-packages/enum                             /opt/zato/2.0.5/zato_extra_paths/
"

# Create symbolic links for zato project to start them at login

ln -s /opt/zato/ulakbus/load-balancer /etc/zato/components-enabled/ulakbus.load-balancer
ln -s /opt/zato/ulakbus/server1 /etc/zato/components-enabled/ulakbus.server1
ln -s /opt/zato/ulakbus/server2 /etc/zato/components-enabled/ulakbus.server2
ln -s /opt/zato/ulakbus/web-admin /etc/zato/components-enabled/ulakbus.web-admin

# Start zato service
service zato start


riak-admin bucket-type create pyoko_models '{"props":{"last_write_wins":true, "allow_mult":false, "n_val":1}}'
riak-admin bucket-type create zengine_models '{"props":{"last_write_wins":true, "allow_mult":false, "n_val":1}}'
riak-admin bucket-type create models '{"props":{"last_write_wins":true, "allow_mult":false, "n_val":1}}'

riak-admin bucket-type activate pyoko_models
riak-admin bucket-type activate zengine_models
riak-admin bucket-type activate models


rm -rf /var/lib/apt/lists/*
