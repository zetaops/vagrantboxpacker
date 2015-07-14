#!/bin/bash
#
# Setup the the box. This runs as root

apt-get -y update
apt-get -y install curl
apt-get -y install git
apt-get -y install apt-file
apt-file update
apt-get -y install software-properties-common

apt-get -y install vim

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
mkdir ~/ulakbus;

zato quickstart create ~/ulakbus sqlite localhost 6379 --kvdb_password='' --verbose;

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

echo "export PYOKO_SETTINGS='ulakbus.settings'" >> /etc/profile

sudo su - ulakbus sh -c "
cd ~

virtualenv --no-site-packages env
source env/bin/activate

pip install --upgrade pip
pip install ipython


pip install riak
pip install enum34
pip install six

pip install git+https://github.com/zetaops/pyoko.git

pip install falcon
pip install beaker
pip install redis
pip install passlib
pip install git+https://github.com/didip/beaker_extensions.git#egg=beaker_extensions
pip install git+https://github.com/zetaops/SpiffWorkflow.git#egg=SpiffWorkflow
pip install git+https://github.com/zetaops/zengine.git#egg=zengine

# install ulakbus dev
git clone https://github.com/zetaops/ulakbus.git
git clone https://github.com/zetaops/ulakbus-ui.git

echo '/app/ulakbus' >> /app/env/lib/python2.7/site-packages/ulakbus.pth

cd ~/env/local/lib/python2.7/site-packages/pyoko/db
wget https://raw.githubusercontent.com/zetaops/pyoko/master/pyoko/db/solr_schema_template.xml

touch /app/env/lib/python2.7/site-packages/google/__init__.py
"

sudo su - zato sh -c "
ln -s /app/ulakbus/ulakbus /opt/zato/2.0.5/zato_extra_paths/
ln -s /app/env/lib/python2.7/site-packages/pyoko /opt/zato/2.0.5/zato_extra_paths/
ln -s /app/env/lib/python2.7/site-packages/riak /opt/zato/2.0.5/zato_extra_paths/
ln -s /app/env/lib/python2.7/site-packages/riak_pb /opt/zato/2.0.5/zato_extra_paths/
ln -s /app/env/lib/python2.7/site-packages/google /opt/zato/2.0.5/zato_extra_paths/
ln -s /app/env/lib/python2.7/site-packages/passlib /opt/zato/2.0.5/zato_extra_paths/
"
