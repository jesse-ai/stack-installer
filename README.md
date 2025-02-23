# Jesse stack installer scripts for Ubuntu

Bash scripts used to install the following stack for running Jesse on fresh Ubuntu installations:

- Python >= `3.11` for Ubuntu 22.04 LTS
- PostgreSQL >= `13`
- Redis >= `5`
- pip >= `21.0.1`
- Oh My Zsh
- Screen

## Installation

Make sure your Ubuntu installation is fresh and execute the appropriate command for your release.

For Ubuntu 22.04 LTS:

```sh
source <(curl -fsSL https://raw.githubusercontent.com/jesse-ai/stack-installer/master/ubuntu-22.04.sh)
```

### Screen usage

`screen` is a must-have for using Jesse's live trade on a remote server. It is used to keep the terminal session alive so you don't have to keep your terminal app (and computer) open all the time!

```sh
sudo apt-get install -y screen
```

You can read more about how to use `screen` at [this blog post](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-screen-on-an-ubuntu-cloud-server), but below commands are all that you need:

```sh
# create and attach to a new screen window
screen -S name_of_the_window

# list all open screens
screen -ls

# reattach to a previously opened window
screen -r name_of_the_window
```
