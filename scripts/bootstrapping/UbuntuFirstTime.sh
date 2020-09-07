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
    linuxbrew-wrapper
    markdown
    make
    nodejs
    npm
    neovim
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

echo "Installing brews..."
BREW_PACKAGES=(
  hashicorp/tap/terraform-ls
)

echo "Installing packages..."
brew install ${BREW_PACKAGES[@]}


if [ ! -f "~/.xbindkeysrc" ]; then
  echo "\"xdotool key 'Control_L+bracketleft'\" \n b:6"
  echo "\"xdotool key 'Control_L+bracketright'\" \n b:7"
fi

if ! -e "~/.profile"; then
 cat ./.profile > ~/.profile
fi

if ! -e "~/.zshrc"; then
 cat ./.zshrc > ~/.zshrc
fi

if ! git config --list | grep -q "user.name"; then
  git config --global user.name $2
  git config --global user.email $3
  git config --global core.editor "vim" 
fi

echo "Creating folder structure..."
[[ ! -d ~/Sites ]] && mkdir ~/Sites

echo "Bootstrapping complete"

echo "Please Reboot"