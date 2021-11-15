#!usr/bin/env bash

start=`date +%s`

echo "updating ubuntu ..."

sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade

# python 3.8
echo "installing Python 3.8 ..."
sudo apt-get -y install gcc binutils
sudo apt-get -y install software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get update -y
sudo apt-get -y install python-pip
sudo apt-get -y install python-setuptools
sudo apt-get -y install build-essential python3.8-dev
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.6 1
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.8 9
sudo update-alternatives  --set python /usr/bin/python3.8
echo "Python 3.8 has been set as default python"
sudo apt-get -y install python-dev
sudo apt-get -y install python3-pip
python -m pip install --upgrade pip
hash -d pip
pip install --upgrade setuptools
pip install ez_setup
pip install Cython numpy


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
sudo apt-get install wget ca-certificates
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
sudo apt-get update -y
sudo apt-get install -y postgresql-14 postgresql-contrib python-psycopg2 libpq-dev

# install screen
echo "installing Screen ..."
sudo apt-get install -y screen

# install pip packages for jesse
echo "installing jesse ..."
pip install -r https://raw.githubusercontent.com/jesse-ai/jesse/master/requirements.txt
pip install jesse
. ~/.profile

echo "cleaning..."
rm ta-lib-0.4.0-src.tar.gz && rm -rf ta-lib
echo "Finished installation. "
end=`date +%s`
runtime=$((end-start))
echo "Installation took ${runtime} seconds."
echo "Notice not to use python3 and pip3, but instead use python and pip."
echo "Here's the output of 'python --version' (it should be 'Python 3.8.*'):"
python --version
echo "Here's the output of 'pip --version':"
pip --version

# install Oh My Zsh
echo "installing Oh My Zsh"
sudo apt-get install -y git zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
