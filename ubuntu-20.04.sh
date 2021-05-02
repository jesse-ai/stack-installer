#!usr/bin/env bash

start=`date +%s`

echo "updating ubuntu ..."
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade

# python 3.x extensions
echo "installing Python 3.x extensions ..."
sudo apt-get -y install gcc binutils
sudo apt-get -y install software-properties-common
sudo apt-get -y install python3-dev python3-pip python3-setuptools
sudo apt-get -y install build-essential
sudo -H pip3 install --upgrade pip
hash -d pip3
pip3 install --upgrade setuptools
pip3 install ez_setup
pip3 install Cython numpy

# talib
echo "installing talib ... (you should have more then 1Gb free of ram)"
sudo apt-get -y install libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev
wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz -q
tar -xzf ta-lib-0.4.0-src.tar.gz
cd ta-lib/
./configure --prefix=/usr
make
sudo make install

# install PosgreSQL database
echo "installing PostgreSQL ..."
cd
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
sudo apt-get update -y
sudo apt-get install -y postgresql postgresql-contrib python3-psycopg2 libpq-dev

# install screen
echo "installing Screen ..."
sudo apt-get install -y screen

# install pip packages for jesse
echo "installing jesse ..."
pip3 install -r https://raw.githubusercontent.com/jesse-ai/jesse/master/requirements.txt
pip3 install jesse
. ~/.profile

echo "cleaning..."
rm ta-lib-0.4.0-src.tar.gz && rm -rf ta-lib
echo "Finished installation. "
end=`date +%s`
runtime=$((end-start))
echo "Installation took ${runtime} seconds."
echo "Here's the output of 'python3 --version' (it should be 'Python 3.x.x'):"
python3 --version
echo "Here's the output of 'pip3 --version':"
pip3 --version

# install Oh My Zsh
echo "installing Oh My Zsh"
sudo apt-get install -y git zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
