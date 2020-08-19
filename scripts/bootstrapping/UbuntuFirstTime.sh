#!/usr/bin/env bash

echo "Starting bootstrapping"

curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - 

APT_PACKAGES=(
    ack
    autoconf
    ansible
    automake
    awscli
    bash-completion
    composer
    chrome-gnome-shell
    docker
    docker.io
    dconf-editor
    ffmpeg
    firefox
    gettext
    git
    github-desktop
    graphviz
    imagemagick
    jq
    markdown
    make
    nodejs
    npm
    net-tools
    nmap
    openssh-server
    default-jdk
    pkg-config
    postgresql
    python3
    thunderbird
    thefuck
    tmux
    tree
    xbindkeys
    xev 
    xdotool
    unrar
    vagrant
    virtualbox
    vim
    vino
    wget
)

echo "adding git desktop"
wget -qO - https://packagecloud.io/shiftkey/desktop/gpgkey | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/shiftkey/desktop/any/ any main" > /etc/apt/sources.list.d/packagecloud-shiftky-desktop.list'
sudo apt-get update

echo "Installing packages..."
sudo apt update -y
sudo apt install -y ${APT_PACKAGES[@]}

echo "Installing terraform"
-mkdir ~/bin
wget https://releases.hashicorp.com/terraform/0.13.0/terraform_0.13.0_linux_amd64.zip
unzip terraform_0.13.0_linux_amd64.zip
mv terraform /usr/local/bin
rm -rf terraform*

echo "Installing snaps..."
SNAP_PACKAGES=(
  rambox
  spotify
)

echo "Installing packages..."
sudo snap install ${SNAP_PACKAGES[@]}

if [ ! -f "~/.xbindkeysrc" ]; then
  echo "\"xdotool key 'Control_L+bracketleft'\" \n b:6"
  echo "\"xdotool key 'Control_L+bracketright'\" \n b:7"
fi

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

echo "Please Reboot"