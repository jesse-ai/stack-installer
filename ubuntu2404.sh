#!/usr/bin/env bash

# Jesse AI Installation Script for Ubuntu 24.04
# This script installs Jesse AI and its dependencies

# Error handling functions
log_error() {
    echo "ERROR: $1" >&2
    echo "Check the logs at /var/log/jesse_install.log for details"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Failed to install $1"
        exit 1
    fi
}

# Trap errors
set -eE
trap 'log_error "Script failed on line $LINENO"' ERR

# Logging setup
exec 1> >(tee -a "/var/log/jesse_install.log")
exec 2>&1

# Define variables
PYTHON_VERSION=3.11
PYTHON_CMD="python${PYTHON_VERSION}"
PIP_CMD="${PYTHON_CMD} -m pip"
VENV_PATH="/opt/jesse_env"
JESSE_PATH="/opt/jesse"
start=$(date +%s)

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root"
    exit 1
fi

# Verify Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)
if [ "$UBUNTU_VERSION" != "24.04" ]; then
    log_error "This script is specifically for Ubuntu 24.04. Detected version: $UBUNTU_VERSION"
    exit 1
fi

# System updates
echo "Updating Ubuntu ..."
apt-get -y update || log_error "Failed to update package list"
apt-get -y upgrade || log_error "Failed to upgrade packages"
apt-get -y dist-upgrade || log_error "Failed to perform distribution upgrade"


# Python installation
echo "Installing Python ${PYTHON_VERSION} and dependencies ..."
apt-get -y install gcc binutils build-essential software-properties-common || log_error "Failed to install build essentials"
add-apt-repository ppa:deadsnakes/ppa -y || log_error "Failed to add Python repository"
apt-get update -y || log_error "Failed to update package list"
apt-get install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-dev python${PYTHON_VERSION}-venv || log_error "Failed to install Python"
Copy

# Verify Python version
installed_python_version=$(${PYTHON_CMD} --version)
if [[ ! "$installed_python_version" =~ "Python ${PYTHON_VERSION}" ]]; then
    log_error "Python ${PYTHON_VERSION} installation failed. Got: $installed_python_version"
    exit 1
fi

# Set up virtual environment
echo "Setting up virtual environment at ${VENV_PATH} ..."
mkdir -p ${VENV_PATH} || log_error "Failed to create virtual environment directory"
${PYTHON_CMD} -m venv ${VENV_PATH} || log_error "Failed to create virtual environment"
source ${VENV_PATH}/bin/activate || log_error "Failed to activate virtual environment"

# Verify virtual environment
if [[ $(which python3) != ${VENV_PATH}* ]]; then
    log_error "Virtual environment not properly activated"
    exit 1
fi

# Upgrade pip and install core packages
${PYTHON_CMD} -m ensurepip --upgrade || log_error "Failed to upgrade pip"
${PIP_CMD} install --upgrade pip setuptools wheel || log_error "Failed to upgrade pip packages"

# Install TA-Lib dependencies
echo "Installing TA-Lib dependencies..."
apt-get -y install libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev || log_error "Failed to install TA-Lib dependencies"

# Install and compile TA-Lib
echo "Installing TA-Lib..."
wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz -q || log_error "Failed to download TA-Lib"
tar -xzf ta-lib-0.4.0-src.tar.gz || log_error "Failed to extract TA-Lib"
cd ta-lib/
./configure --prefix=/usr || log_error "Failed to configure TA-Lib"
make || log_error "Failed to make TA-Lib"
make install || log_error "Failed to install TA-Lib"
cd ..

# Install core Python packages
echo "Installing core Python packages..."
python3 -m pip install numpy==1.23.0 Cython || log_error "Failed to install core Python packages"

# Install PostgreSQL 15
echo "Installing PostgreSQL..."
sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' || log_error "Failed to add PostgreSQL repository"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - || log_error "Failed to add PostgreSQL key"
apt-get update -y || log_error "Failed to update package list"
apt-get install -y postgresql-15 postgresql-contrib python3-psycopg2 libpq-dev || log_error "Failed to install PostgreSQL"

# Configure PostgreSQL
echo "Configuring PostgreSQL..."
sudo -u postgres psql -c "CREATE DATABASE jesse_db;" || log_error "Failed to create database"
sudo -u postgres psql -c "CREATE USER jesse_user WITH PASSWORD 'password123';" || log_error "Failed to create database user"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE jesse_db TO jesse_user;" || log_error "Failed to grant privileges"

# Verify PostgreSQL
if ! systemctl is-active --quiet postgresql; then
    log_error "PostgreSQL service is not running"
    exit 1
fi

# Install Redis
echo "Installing Redis..."
apt-get install -y redis-server || log_error "Failed to install Redis"
systemctl enable redis-server || log_error "Failed to enable Redis service"
systemctl start redis-server || log_error "Failed to start Redis service"

# Verify Redis
if ! systemctl is-active --quiet redis-server; then
    log_error "Redis service is not running"
    exit 1
fi
redis-cli ping > /dev/null || log_error "Redis is not responding"

# Install Screen
echo "Installing Screen..."
apt-get install -y screen || log_error "Failed to install Screen"
check_command screen

# Install Jesse and dependencies
echo "Installing Jesse..."
python3 -m pip install --no-cache-dir -r https://raw.githubusercontent.com/jesse-ai/jesse/master/requirements.txt || log_error "Failed to install Jesse requirements"
python3 -m pip install --no-cache-dir jesse || log_error "Failed to install Jesse"

# Verify Jesse installation
python3 -c "import jesse; print(f'Jesse version: {jesse.__version__}')" || log_error "Jesse import failed"

# Install Oh My Zsh and shell configuration
echo "Installing Oh My Zsh..."
apt-get install -y git zsh || log_error "Failed to install git and zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || log_error "Failed to install Oh My Zsh"

# Create and configure Jesse directories
mkdir -p ${JESSE_PATH}/config || log_error "Failed to create Jesse config directory"
chown -R $SUDO_USER:$SUDO_USER ${JESSE_PATH} || log_error "Failed to set Jesse directory permissions"

# Create dedicated environment file
cat > ${JESSE_PATH}/config/jesse_env << EOL || log_error "Failed to create environment file"
export JESSE_ENV="production"
export JESSE_PATH="${JESSE_PATH}"
export VIRTUAL_ENV="${VENV_PATH}"
export PATH="\${VIRTUAL_ENV}/bin:\${PATH}"
EOL

# Configure both shells (zsh and bash)
for rcfile in ~/.zshrc ~/.bashrc; do
    cp ${rcfile} ${rcfile}.backup || log_error "Failed to backup ${rcfile}"
    cat >> ${rcfile} << EOL || log_error "Failed to update ${rcfile}"
# Jesse Configuration
if [ -f ${JESSE_PATH}/config/jesse_env ]; then
    source ${JESSE_PATH}/config/jesse_env
    source ${VENV_PATH}/bin/activate
fi
EOL
done

# Cleanup
echo "Cleaning up..."
rm -f ta-lib-0.4.0-src.tar.gz || log_error "Failed to remove TA-Lib archive"
rm -rf ta-lib || log_error "Failed to remove TA-Lib directory"

# Installation summary
end=$(date +%s)
runtime=$((end-start))
echo "============================================"
echo "Installation Summary:"
echo "--------------------------------------------"
echo "Installation completed in ${runtime} seconds"
echo "Ubuntu version: ${UBUNTU_VERSION}"
echo "Python version: $(python3 --version)"
echo "Pip version: $(python3 -m pip --version)"
echo "Jesse version: $(python3 -c 'import jesse; print(jesse.__version__)')"
echo "PostgreSQL version: $(psql --version)"
echo "Redis version: $(redis-cli --version)"
echo "Log file: /var/log/jesse_install.log"
echo "============================================"
echo "Please log out and back in for all changes to take effect."
