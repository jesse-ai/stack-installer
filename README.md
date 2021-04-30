# Jesse stack installer scripts for Ubuntu LTS

Bash scripts used to install below stack for running Jesse on fresh Ubuntu LTS installations:

- Python >= `3.8`
- PostgreSQL >= `13`
- ta-lib >= `0.4`
- pip >= `21.0.1`
- Oh My Zsh
- Screen

<!-- Currently there is one script for Ubuntu 18.04 LTS and one script for Ubuntu 20.04 LTS. -->
Currently there is only one script for **Ubuntu 18.04**. A script for Ubuntu 20.04 is under work. 

## Installation

Make sure your Ubuntu installaton is fresh and execute the appropriate command for your release.

```sh
# For Ubuntu 18.04 LTS
source <(curl -fsSL https://raw.githubusercontent.com/jesse-ai/stack-installer/master/ubuntu-18.04.sh)
```

<!-- # For Ubuntu 20.04 LTS
source <(curl -fsSL https://raw.githubusercontent.com/jesse-ai/stack-installer/master/ubuntu-20.04.sh) -->

### Screen usage

`screen` is a must have for using Jesse's live trade on a remote server. It is used to keep the terminal session alive so you don't have to keep your terminal app (and computer) open all the time!

```sh
sudo apt-get install -y screen
```

You can read more about how to use `screen` at [this blog post](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-screen-on-an-ubuntu-cloud-server), but below commands are basically all that you need:

```sh
# create and attach to a new screen window
screen -S name_of_the_window

# list all open screens
screen -ls

# reattach to a previously opened window
screen -r name_of_the_window
```
