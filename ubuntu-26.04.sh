#!/usr/bin/env bash

#############################################
# Jesse stack installer
# Supported system: Ubuntu 26.04 LTS (fresh install)
# Last updated: 2026-10-24
#
# Installs:
# - Miniconda with a "jesse" conda environment (Python 3.13 by default)
# - PostgreSQL 17 with TimescaleDB, plus the jesse_db database and jesse_user
# - Jesse (latest from PyPI) and a project created from jesse-ai/project-template
# - Screen, Zsh and Oh My Zsh
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/jesse-ai/stack-installer/master/ubuntu-26.04.sh -o install-jesse.sh
#   sudo bash install-jesse.sh
#
# Options (environment variables):
#   PYTHON_VERSION=3.13      Python version of the conda environment
#   PG_VERSION=17            PostgreSQL major version
#   PROJECT_NAME=my-bot      Name of the project directory created in your home
#   INSTALL_OH_MY_ZSH=yes    Set to "no" to skip Zsh / Oh My Zsh
#############################################

SUPPORTED_UBUNTU="26.04"

PYTHON_VERSION="${PYTHON_VERSION:-3.13}"
PG_VERSION="${PG_VERSION:-17}"
PROJECT_NAME="${PROJECT_NAME:-my-bot}"
INSTALL_OH_MY_ZSH="${INSTALL_OH_MY_ZSH:-yes}"
DB_NAME="jesse_db"
DB_USER="jesse_user"
DB_PASSWORD="password"

LOG_DIR="/var/log/jesse"
LOG_FILE="${LOG_DIR}/jesse_install.log"

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
    echo "Check the log at ${LOG_FILE} for details" >&2
}

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root, for example: sudo bash ubuntu-${SUPPORTED_UBUNTU}.sh"
    exit 1
fi

set -eEuo pipefail
trap 'log_error "Script failed on line $LINENO: $BASH_COMMAND"' ERR

mkdir -p "${LOG_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1

start=$(date +%s)
export DEBIAN_FRONTEND=noninteractive

# A fresh server is often still running cloud-init or automatic updates; wait for the apt lock instead of failing.
apt_get() {
    apt-get -o DPkg::Lock::Timeout=900 "$@"
}

# The user who gets Miniconda and the Jesse project: the sudo caller, or root.
TARGET_USER="${SUDO_USER:-root}"
TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
CONDA_DIR="${TARGET_HOME}/miniconda3"
PROJECT_DIR="${TARGET_HOME}/${PROJECT_NAME}"

as_user() {
    if [ "${TARGET_USER}" = "root" ]; then
        bash -c "$1"
    else
        sudo -u "${TARGET_USER}" -H bash -c "$1"
    fi
}

UBUNTU_VERSION="$(. /etc/os-release && echo "${VERSION_ID}")"
UBUNTU_CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
if [ "${UBUNTU_VERSION}" != "${SUPPORTED_UBUNTU}" ]; then
    log_error "This script is for Ubuntu ${SUPPORTED_UBUNTU}. Detected: ${UBUNTU_VERSION}. Use the script for your release."
    exit 1
fi
log_info "Ubuntu ${UBUNTU_VERSION} (${UBUNTU_CODENAME}), installing for user ${TARGET_USER}"

total_memory=$(free -m | awk '/^Mem:/{print $2}')
if [ "${total_memory}" -lt 1900 ]; then
    log_error "At least 2 GB of RAM is required, detected ${total_memory} MB"
    exit 1
fi

case "$(uname -m)" in
    x86_64) CONDA_ARCH="x86_64" ;;
    aarch64) CONDA_ARCH="aarch64" ;;
    *) log_error "Unsupported CPU architecture: $(uname -m)"; exit 1 ;;
esac

log_info "Updating system packages..."
if command -v cloud-init &> /dev/null; then
    cloud-init status --wait > /dev/null 2>&1 || true
fi
apt_get -y update
apt_get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
apt_get -y install build-essential gcc git curl wget ca-certificates gnupg lsb-release screen

log_info "Adding the PostgreSQL and TimescaleDB repositories..."
install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor --yes -o /etc/apt/keyrings/postgresql.gpg
echo "deb [signed-by=/etc/apt/keyrings/postgresql.gpg] https://apt.postgresql.org/pub/repos/apt ${UBUNTU_CODENAME}-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list
curl -fsSL https://packagecloud.io/timescale/timescaledb/gpgkey | gpg --dearmor --yes -o /etc/apt/keyrings/timescaledb.gpg
echo "deb [signed-by=/etc/apt/keyrings/timescaledb.gpg] https://packagecloud.io/timescale/timescaledb/ubuntu/ ${UBUNTU_CODENAME} main" \
    > /etc/apt/sources.list.d/timescaledb.list
apt_get -y update

log_info "Installing PostgreSQL ${PG_VERSION} and TimescaleDB..."
apt_get -y install "postgresql-${PG_VERSION}" "postgresql-client-${PG_VERSION}" libpq-dev \
    "timescaledb-2-postgresql-${PG_VERSION}" timescaledb-tools

# Preload the TimescaleDB library and tune memory settings for this machine.
timescaledb-tune --quiet --yes --pg-version "${PG_VERSION}" > /dev/null
systemctl enable postgresql
systemctl restart postgresql
for _ in $(seq 1 30); do
    sudo -u postgres pg_isready -q && break
    sleep 1
done
sudo -u postgres pg_isready -q || { log_error "PostgreSQL did not start"; exit 1; }

log_info "Creating the ${DB_NAME} database and ${DB_USER} user..."
psql_su() { sudo -u postgres psql -v ON_ERROR_STOP=1 -qtAX "$@"; }
if [ -z "$(psql_su -c "SELECT 1 FROM pg_roles WHERE rolname = '${DB_USER}'")" ]; then
    psql_su -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';"
fi
if [ -z "$(psql_su -c "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'")" ]; then
    psql_su -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};"
fi
psql_su -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"
# Creating the extension needs a superuser; Jesse then sets up the candle table itself.
psql_su -d "${DB_NAME}" -c "CREATE EXTENSION IF NOT EXISTS timescaledb WITH SCHEMA public;"
TSDB_VERSION="$(psql_su -d "${DB_NAME}" -c "SELECT extversion FROM pg_extension WHERE extname = 'timescaledb'")"
log_info "PostgreSQL ready with TimescaleDB ${TSDB_VERSION}"

log_info "Installing Miniconda for ${TARGET_USER}..."
if [ ! -x "${CONDA_DIR}/bin/conda" ]; then
    as_user "curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-${CONDA_ARCH}.sh -o /tmp/miniconda.sh \
        && bash /tmp/miniconda.sh -b -u -p '${CONDA_DIR}' && rm -f /tmp/miniconda.sh"
fi

log_info "Creating the 'jesse' conda environment with Python ${PYTHON_VERSION}..."
# conda-forge only, so no Anaconda channel terms of service prompt is needed.
if [ ! -d "${CONDA_DIR}/envs/jesse" ]; then
    as_user "'${CONDA_DIR}/bin/conda' create -y -q -n jesse --override-channels -c conda-forge python=${PYTHON_VERSION}"
fi
JESSE_PY="${CONDA_DIR}/envs/jesse/bin/python"

log_info "Installing Jesse..."
if [ "${PYTHON_VERSION}" != "3.12" ]; then
    log_info "Jesse's pinned numpy has no prebuilt wheel for Python ${PYTHON_VERSION}; it is compiled from source, which takes about 10-15 minutes on a small server."
fi
as_user "'${JESSE_PY}' -m pip install --no-cache-dir --upgrade pip"
as_user "'${JESSE_PY}' -m pip install --no-cache-dir jesse"
JESSE_VERSION="$(as_user "'${JESSE_PY}' -c 'import jesse.version as v; print(v.__version__)'")"
log_info "Jesse ${JESSE_VERSION} installed"

log_info "Creating the project at ${PROJECT_DIR}..."
if [ ! -d "${PROJECT_DIR}" ]; then
    as_user "git clone -q https://github.com/jesse-ai/project-template '${PROJECT_DIR}'"
    as_user "cd '${PROJECT_DIR}' && cp .env.example .env \
        && sed -i -e 's/^POSTGRES_HOST=.*/POSTGRES_HOST=localhost/' -e 's/^TIMESCALEDB_ENABLED=.*/TIMESCALEDB_ENABLED=TRUE/' .env"
fi

if [ "${INSTALL_OH_MY_ZSH}" = "yes" ]; then
    log_info "Installing Zsh and Oh My Zsh..."
    apt_get -y install zsh
    if [ ! -d "${TARGET_HOME}/.oh-my-zsh" ]; then
        as_user 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
    fi
    chsh -s "$(command -v zsh)" "${TARGET_USER}"
fi

log_info "Initialising conda for the shells..."
as_user "'${CONDA_DIR}/bin/conda' init bash > /dev/null"
[ -f "${TARGET_HOME}/.zshrc" ] && as_user "'${CONDA_DIR}/bin/conda' init zsh > /dev/null"
for rcfile in "${TARGET_HOME}/.bashrc" "${TARGET_HOME}/.zshrc"; do
    if [ -f "${rcfile}" ] && ! grep -q "conda activate jesse" "${rcfile}"; then
        printf '\n# Jesse\nconda activate jesse\n' >> "${rcfile}"
    fi
done

apt_get -y autoremove
apt_get -y clean

end=$(date +%s)
log_info "============================================"
log_info "Installation completed in $((end - start)) seconds"
log_info "Ubuntu:      ${UBUNTU_VERSION}"
log_info "Python:      $("${JESSE_PY}" --version 2>&1)"
log_info "Jesse:       ${JESSE_VERSION}"
log_info "PostgreSQL:  $(sudo -u postgres psql -qtAX -c 'SHOW server_version' | cut -d' ' -f1)"
log_info "TimescaleDB: ${TSDB_VERSION}"
log_info "Project:     ${PROJECT_DIR}"
log_info "Log file:    ${LOG_FILE}"
log_info "============================================"
log_info "Log out and back in (or open a new terminal), then run:"
log_info "  cd ${PROJECT_DIR} && jesse run"
