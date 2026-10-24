# Jesse stack installer scripts for Ubuntu

Bash scripts that install everything needed to run Jesse on a fresh Ubuntu server:

- Miniconda, with a `jesse` conda environment (Python `3.12`)
- PostgreSQL `17` with TimescaleDB, and the `jesse_db` database owned by `jesse_user`
- Jesse (latest release from PyPI)
- A Jesse project in `~/my-bot`, created from [project-template](https://github.com/jesse-ai/project-template) and set up for this machine (`POSTGRES_HOST=localhost`, `TIMESCALEDB_ENABLED=TRUE`)
- Screen, Zsh and Oh My Zsh

Redis is no longer needed: Jesse 3 ships its own coordination service.

## Installation

Use the script for your Ubuntu release on a fresh installation, as root or with `sudo`. Miniconda and the project are installed for the user who runs `sudo` (or for root).

Ubuntu 26.04 LTS:

```sh
curl -fsSL https://raw.githubusercontent.com/jesse-ai/stack-installer/master/ubuntu-26.04.sh -o install-jesse.sh
sudo bash install-jesse.sh
```

Ubuntu 24.04 LTS:

```sh
curl -fsSL https://raw.githubusercontent.com/jesse-ai/stack-installer/master/ubuntu-24.04.sh -o install-jesse.sh
sudo bash install-jesse.sh
```

Ubuntu 22.04 LTS:

```sh
curl -fsSL https://raw.githubusercontent.com/jesse-ai/stack-installer/master/ubuntu-22.04.sh -o install-jesse.sh
sudo bash install-jesse.sh
```

The server needs at least 2 GB of RAM. A log of the installation is written to `/var/log/jesse/jesse_install.log`.

When it finishes, log out and back in (the `jesse` environment is then activated automatically) and start Jesse:

```sh
cd ~/my-bot
jesse run
```

Change `PASSWORD` in `~/my-bot/.env` before exposing the dashboard to the internet.

### Options

Set these environment variables before running the script to change the defaults:

| Variable | Default | Description |
|---|---|---|
| `PYTHON_VERSION` | `3.12` | Python version of the `jesse` conda environment. `3.13` also works, but Jesse's pinned numpy is then compiled from source, which adds about 10-15 minutes |
| `PG_VERSION` | `17` | PostgreSQL major version |
| `PROJECT_NAME` | `my-bot` | Name of the project directory created in your home directory |
| `INSTALL_OH_MY_ZSH` | `yes` | Set to `no` to skip Zsh and Oh My Zsh |

For example: `sudo PROJECT_NAME=trader bash install-jesse.sh`

### Screen usage

`screen` is a must-have for using Jesse's live trade on a remote server. It keeps the terminal session alive so you don't have to keep your terminal app (and computer) open all the time.

```sh
# create and attach to a new screen window
screen -S name_of_the_window

# list all open screens
screen -ls

# reattach to a previously opened window
screen -r name_of_the_window
```

You can read more about `screen` in [this blog post](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-screen-on-an-ubuntu-cloud-server).
