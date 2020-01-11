#!/bin/bash

start=`date +%s`

echo "updaing ubuntu..."
sudo apt-get -y update > /dev/null
sudo apt-get -y upgrade > /dev/null

# python 3.8
echo "installing Python 3.8 ..."
sudo apt-get -y install gcc binutils > /dev/null
sudo apt-get update > /dev/null
sudo apt-get install software-properties-common > /dev/null
sudo add-apt-repository -y ppa:deadsnakes/ppa > /dev/null
sudo apt-get update -y > /dev/null
sudo apt-get -y install python-pip > /dev/null
sudo apt-get -y install python-setuptools > /dev/null
sudo apt-get -y install build-essential python3.8-dev > /dev/null
sudo apt-get update > /dev/null
sudo apt-get install build-essential > /dev/null
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.6 1
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.8 9
sudo update-alternatives  --set python /usr/bin/python3.8
echo "Python 3.8 has been set as default python"
sudo apt-get -y install python-dev > /dev/null
sudo apt-get -y install python3-pip > /dev/null
python -m pip install --upgrade pip > /dev/null
hash -d pip > /dev/null
pip install -U setuptools > /dev/null
pip install --upgrade setuptools > /dev/null
pip install ez_setup > /dev/null
pip install Cython numpy > /dev/null


# talib
echo "installing talib ..."
sudo apt-get -y install libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev python3.8-dev > /dev/null
wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz -q
tar -xzf ta-lib-0.4.0-src.tar.gz > /dev/null
cd ta-lib/ 
./configure --prefix=/usr > /dev/null
make > /dev/null
sudo make install > /dev/null

# install PosgreSQL database
echo "installing PostgreSQL ..."
cd
sudo apt-get install wget ca-certificates > /dev/null
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list' > /dev/null
sudo apt-get update -y > /dev/null
sudo apt-get install -y postgresql postgresql-contrib python-psycopg2 libpq-dev > /dev/null

# install Redis
echo "installing Redis..."
sudo apt-get -y update > /dev/null
sudo apt-get install redis-server -y > /dev/null
# edit "supervised no" to "supervised systemd" in redis.conf
sed -i 's/supervised no/supervised systemd/' /etc/redis/redis.conf


echo "cleaning..."
rm ta-lib-0.4.0-src.tar.gz && rm -rf ta-lib


echo "Finished stack installation. You may now create a database, pull Jesse, and start trading."
end=`date +%s`
runtime=$((end-start))
echo "Installation took ${runtime} seconds."
echo "Notice not to use python3 and pip3, but instead use python and pip."
echo "Here's the output of 'python --version' (it should be 'Python 3.8.1'):"
python --version
echo "Here's the output of 'pip --version' (it should start with 'pip 19.3.1'):"
pip --version