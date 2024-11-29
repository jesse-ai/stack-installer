```bash
#!/usr/bin/env bash

#############################################
# Jesse AI Installation Script
# Supported Systems: Ubuntu 22.04 LTS, Ubuntu 24.04 LTS
# Version: 2.0
# Last Updated: 2024-11-29
#
# Requirements:
# - Ubuntu 22.04 or 24.04
# - Root access
# - Minimum 2GB RAM
#
# Usage:
# 1. Save this script as install-jesse.sh
# 2. Make it executable: chmod +x install-jesse.sh
# 3. Run as root: sudo ./install-jesse.sh
#
# This script will:
# - Install Python 3.11 and required dependencies
# - Set up PostgreSQL database
# - Install and configure Redis
# - Install TA-Lib
# - Install and configure Jesse
# - Set up shell environment (bash and zsh)
#############################################

# Error handling functions
log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[ERROR] ${timestamp} - $1" >&2
    echo "[ERROR] ${timestamp} - $1" >> "${LOG_FILE}"
    echo "Check the logs at ${LOG_FILE} for details"
}

log_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[INFO] ${timestamp} - $1"
    echo "[INFO] ${timestamp} - $1" >> "${LOG_FILE}"
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

# Log directory setup
LOG_DIR="/var/log/jesse"
LOG_FILE="${LOG_DIR}/jesse_install.log"
mkdir -p ${LOG_DIR}

# Logging setup
exec 1> >(tee -a "${LOG_FILE}")
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

# Version detection and validation
UBUNTU_VERSION=$(lsb_release -rs)
if [[ "$UBUNTU_VERSION" != "22.04" && "$UBUNTU_VERSION" != "24.04" ]]; then
    log_error "This script is for Ubuntu 22.04 or 24.04. Detected version: $UBUNTU_VERSION"
    exit 1
fi

log_info "Detected Ubuntu version: $UBUNTU_VERSION"

# Version-specific warnings
if [[ "$UBUNTU_VERSION" == "24.04" ]]; then
    log_info "Note: Using Ubuntu 24.04. Some package versions may be newer than in documentation."
    log_info "Package versions will be logged for reference."
fi

# System requirements check
total_memory=$(free -m | awk '/^Mem:/{print $2}')
if [ $total_memory -lt 2048 ]; then
    log_error "Insufficient memory. Minimum 2GB RAM required, detected: ${total_memory}MB"
    exit 1
fi

# System updates and base dependencies
log_info "Updating Ubuntu system packages..."
apt-get -y update || log_error "Failed to update package list"
apt-get -y upgrade || log_error "Failed to upgrade packages"
apt-get -y dist-upgrade || log_error "Failed to perform distribution upgrade"

# Install basic dependencies
log_info "Installing basic dependencies..."
apt-get -y install gcc binutils build-essential software-properties-common \
    wget curl git || log_error "Failed to install build essentials"

# Python installation
log_info "Installing Python ${PYTHON_VERSION}..."
add-apt-repository ppa:deadsnakes/ppa -y || log_error "Failed to add Python repository"
apt-get update -y || log_error "Failed to update after adding Python repository"
apt-get install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-dev \
    python${PYTHON_VERSION}-venv || log_error "Failed to install Python"

# Verify Python installation
installed_python_version=$(${PYTHON_CMD} --version)
if [[ ! "$installed_python_version" =~ "Python ${PYTHON_VERSION}" ]]; then
    log_error "Python ${PYTHON_VERSION} installation failed. Got: $installed_python_version"
    exit 1
fi
log_info "Python ${PYTHON_VERSION} installed successfully"

# Set up virtual environment
log_info "Setting up virtual environment at ${VENV_PATH}..."
mkdir -p ${VENV_PATH} || log_error "Failed to create virtual environment directory"
${PYTHON_CMD} -m venv ${VENV_PATH} || log_error "Failed to create virtual environment"
source ${VENV_PATH}/bin/activate || log_error "Failed to activate virtual environment"

# Verify virtual environment
if [[ $(which python3) != ${VENV_PATH}* ]]; then
    log_error "Virtual environment not properly activated"
    exit 1
fi

# Install TA-Lib dependencies
log_info "Installing TA-Lib dependencies..."
apt-get -y install libncurses5-dev libgdbm-dev libnss3-dev libssl-dev \
    libreadline-dev libffi-dev || log_error "Failed to install TA-Lib dependencies"

# Install and compile TA-Lib
log_info "Installing TA-Lib..."
wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz -q || log_error "Failed to download TA-Lib"
tar -xzf ta-lib-0.4.0-src.tar.gz || log_error "Failed to extract TA-Lib"
cd ta-lib/
./configure --prefix=/usr || log_error "Failed to configure TA-Lib"
make || log_error "Failed to make TA-Lib"
make install || log_error "Failed to install TA-Lib"
cd ..

# Install core Python packages
log_info "Installing core Python packages..."
python3 -m pip install numpy==1.23.0 Cython || log_error "Failed to install core Python packages"

# PostgreSQL version based on Ubuntu version
if [[ "$UBUNTU_VERSION" == "24.04" ]]; then
    PG_VERSION="15"
else
    PG_VERSION="13"
fi

# Install PostgreSQL
log_info "Installing PostgreSQL ${PG_VERSION}..."
sh -c "echo 'deb https://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main' > /etc/apt/sources.list.d/pgdg.list" || \
    log_error "Failed to add PostgreSQL repository"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - || \
    log_error "Failed to add PostgreSQL key"
apt-get update -y || log_error "Failed to update package list"
apt-get install -y postgresql-${PG_VERSION} postgresql-contrib python3-psycopg2 libpq-dev || \
    log_error "Failed to install PostgreSQL"

# Configure PostgreSQL
log_info "Configuring PostgreSQL..."
sudo -u postgres psql -c "CREATE DATABASE jesse_db;" || log_error "Failed to create database"
sudo -u postgres psql -c "CREATE USER jesse_user WITH PASSWORD 'password123';" || log_error "Failed to create database user"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE jesse_db TO jesse_user;" || log_error "Failed to grant privileges"

# Verify PostgreSQL
if ! systemctl is-active --quiet postgresql; then
    log_error "PostgreSQL service is not running"
    exit 1
fi
log_info "PostgreSQL configured successfully"

# Install Redis
log_info "Installing Redis..."
apt-get install -y redis-server || log_error "Failed to install Redis"
systemctl enable redis-server || log_error "Failed to enable Redis service"
systemctl start redis-server || log_error "Failed to start Redis service"

# Verify Redis
if ! systemctl is-active --quiet redis-server; then
    log_error "Redis service is not running"
    exit 1
fi
redis-cli ping > /dev/null || log_error "Redis is not responding"
log_info "Redis installed and running"

# Install Screen
log_info "Installing Screen..."
apt-get install -y screen || log_error "Failed to install Screen"
check_command screen

# Install Jesse and dependencies
log_info "Installing Jesse..."
python3 -m pip install --no-cache-dir -r https://raw.githubusercontent.com/jesse-ai/jesse/master/requirements.txt || \
    log_error "Failed to install Jesse requirements"
python3 -m pip install --no-cache-dir jesse || log_error "Failed to install Jesse"

# Verify Jesse installation
python3 -c "import jesse; print(f'Jesse version: {jesse.__version__}')" || log_error "Jesse import failed"
log_info "Jesse installed successfully"

# Install Oh My Zsh and shell configuration
log_info "Installing Oh My Zsh..."
apt-get install -y git zsh || log_error "Failed to install git and zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || \
    log_error "Failed to install Oh My Zsh"

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
    cp ${rcfile} ${rcfile}.backup-$(date +%Y%m%d) || log_error "Failed to backup ${rcfile}"
    cat >> ${rcfile} << EOL || log_error "Failed to update ${rcfile}"
# Jesse Configuration
if [ -f ${JESSE_PATH}/config/jesse_env ]; then
    source ${JESSE_PATH}/config/jesse_env
    source ${VENV_PATH}/bin/activate
fi
EOL
done

git clone https://github.com/jesse-ai/project-template /opt/jesse/my-bot

# Cleanup
log_info "Cleaning up..."
rm -f ta-lib-0.4.0-src.tar.gz || log_error "Failed to remove TA-Lib archive"
rm -rf ta-lib || log_error "Failed to remove TA-Lib directory"

# Installation summary
end=$(date +%s)
runtime=$((end-start))
log_info "============================================"
log_info "Installation Summary:"
log_info "--------------------------------------------"
log_info "Installation completed in ${runtime} seconds"
log_info "Ubuntu version: ${UBUNTU_VERSION}"
log_info "Python version: $(python3 --version)"
log_info "Pip version: $(python3 -m pip --version)"
#log_info "Jesse version: $(python3 -c 'import jesse; print(jesse.__version__)')"
log_info "PostgreSQL version: $(psql --version)"
log_info "Redis version: $(redis-cli --version)"
log_info "Log file: ${LOG_FILE}"
log_info "============================================"
log_info "Please log out and back in for all changes to take effect."
```