# Jesse stack installer script for Ubuntu 18.04

A bash script used to install the required stack for running Jesse on a fresh Ubuntu 18.04:

-   Python >= `3.8`
-   PostgreSQL >= `11.2`
-   Redis >= `5`
-   ta-lib >= `0.4`
-   pip >= `19.3.0`

## Installation
Make sure your Ubuntu 18.04 is fresh:
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/jesse-ai/stack-installer/master/ubuntu-18.04.sh)"
```

## Extra packages
Below packages are not required to run Jesse but are very useful:

### [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)

```sh
sudo apt-get install -y zsh && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### [screen](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-screen-on-an-ubuntu-cloud-server)
A must have for using Jesse on a remote server. It is used to keep the terminal sessions alive.
```sh
sudo apt-get install -y screen
```

Usage example (maybe all the commands you need):
```sh
# create and attach to a new screen window
screen -S name_of_the_window

# list all open screens
screen -ls

# reattach to a previously opened window
screen -r name_of_the_window
```
