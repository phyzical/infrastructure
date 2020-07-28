#!/usr/bin/env bash

echo "Starting bootstrapping"

curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - 

APT_PACKAGES=(
    make
    ack
    autoconf
    ansible
    automake
    docker
    docker.io
    ffmpeg
    gettext
    git
    graphviz
    imagemagick
    jq
    markdown
    nodejs
    npm
    thunderbird
    firefox
    openssh-server
    pkg-config
    postgresql
    python3
    tmux
    tree
    vim
    wget
    nmap
    bash-completion
    unrar
    thefuck
    vagrant
    virtualbox
    net-tools
    awscli
    composer
)

echo "Installing packages..."
sudo apt update -y
sudo apt install -y ${APT_PACKAGES[@]}

sudo add-apt-repository 'deb https://gitblade.com/ppa ./'
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6ECD108C66165FE8
sudo apt update
sudo apt install gitblade

echo "Installing snaps..."
SNAP_PACKAGES=(
  rambox
  spotify
)

echo "Installing packages..."
sudo snap install ${SNAP_PACKAGES[@]}

if [ ! -f "~/.bash_profile" ]; then
  echo 'export ANDROID_HOME="~/Library/Android/sdk"' >> ~/.bash_profile
  echo 'export PATH=~/Library/Python/2.7/bin/:$PATH' >> ~/.bash_profile
  echo 'export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH"' >> ~/.bash_profile
  echo 'export PATH="$PATH:/Applications/MAMP/Library/bin"' >> ~/.bash_profile
  echo 'export PATH=/opt/local/bin:/opt/local/sbin:$PATH' >> ~/.bash_profile
  echo 'eval $(thefuck --alias)' >> ~/.bash_profile
  echo 'GITPS1="\$(__git_ps1 \"(%s)\")"' >> ~/.bash_profile
  echo 'PS1="\n${GITPS1}\n[\t][\u@\h:\W] \$ "' >> ~/.bash_profile
  echo 'PUBLICIP="dig +short myip.opendns.com @resolver1.opendns.com"' >> ~/.bash_profile
  echo "LOCALIP=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')" >> ~/.bash_profile
fi

if ! git config --list | grep -q "user.name"; then
  git config --global user.name $2
  git config --global user.email $3
fi

echo "Creating folder structure..."
[[ ! -d ~/Sites ]] && mkdir ~/Sites

echo "Bootstrapping complete"
