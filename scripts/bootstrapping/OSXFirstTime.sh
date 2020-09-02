#!/usr/bin/env bash

echo "Starting bootstrapping"

# Ask for the administrator password upfront
sudo -v

## set pc name
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$1"

# Update homebrew recipes
brew update

# Install GNU core utilities (those that come with OS X are outdated)
brew tap Homebrew/homebrew-core
brew install coreutils
brew install grep 
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, g-prefixed
brew install findutils

# Install Bash 4
brew install bash

PACKAGES=(
    ack
    autoconf
    automake
    ansible
    awscli
    boot2docker
    composer
    dep
    ffmpeg
    gettext
    gifsicle
    git
    graphviz
    hashicorp/tap/terraform-ls
    hub
    imagemagick
    jq
    libjpeg
    libmemcached 
    lynx
    markdown
    memcached
    mercurial
    npm
    pkg-config
    postgresql
    python3
    pypy
    rabbitmq
    rename
    ssh-copy-id
    terminal-notifier
    tmux
    tree
    vim
    wget
    geoip
    nmap
    # not needed anymore cause zsh lyfe
    #bash-completion
    watchman
    unrar
    thefuck
    terraform
)

echo "Installing packages..."
brew install ${PACKAGES[@]}

echo "Cleaning up..."
brew cleanup

echo "Installing cask..."

CASKS=(
    aws-vault
    android-studio
    android-sdk
    android-platform-tools
    dash
    firefox
    flux
    gitup
    google-chrome
    iterm2
    jetbrains-toolbox
    mamp
    rambox
    rectangle
    react-native-debugger
    spectacle
    sublime-text
    spotify
    tunnelblick
    thunderbird
    vagrant
    virtualbox
    vlc
    visual-studio-code
)

if ! -e "~/.profile"; then
 cat ./.profile > ~/.profile
fi

if ! -e "~/.zshrc"; then
 cat ./.zshrc > ~/.zshrc
fi

if ! git config --list | grep -q "user.name"; then
 git config --global user.name $2
 git config --global user.email $3
fi

echo "Installing cask apps..."
brew cask install ${CASKS[@]}

echo "Installing Ruby gems"
RUBY_GEMS=(
    cocoapods
)
sudo gem install ${RUBY_GEMS[@]}

echo "Configuring OSX Settings..."

# Require password as soon as screensaver or sleep mode starts
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Show filename extensions by default
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

#show hidden files
defaults write com.apple.finder AppleShowAllFiles YES

# Disable "natural" scroll
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# sets a hard click
defaults write NSGlobalDomain FirstClickThreshold -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad FirstClickThreshold -int 2
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 2

# Enable tap-to-click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

## DISABLE THE “ARE YOU SURE YOU WANT TO OPEN THIS APPLICATION?” DIALOG
defaults write com.apple.LaunchServices LSQuarantine -bool false

# sets bottom right right click
defaults write NSGlobalDomain TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 2

# sets right click true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults write NSGlobalDomain TrackpadRightClick -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true

#Turn off keyboard illumination when computer is not used for 5 minutes
defaults write com.apple.BezelServices kDimTime -int 300

echo "Creating folder structure..."
[[ ! -d ~/Sites ]] && mkdir ~/Sites

# Menu bar: hide the useless Time Machine and Volume icons
defaults write com.apple.systemuiserver menuExtras -array "/System/Library/CoreServices/Menu Extras/Display.menu" "/System/Library/CoreServices/Menu Extras/Volume.menu" "/System/Library/CoreServices/Menu Extras/Bluetooth.menu" "/System/Library/CoreServices/Menu Extras/Bluetooth.menu" "/System/Library/CoreServices/Menu Extras/AirPort.menu" "/System/Library/CoreServices/Menu Extras/Battery.menu" "/System/Library/CoreServices/Menu Extras/Clock.menu"

# hide siri
defaults write com.apple.systemuiserver "NSStatusItem Visible Siri" -bool false

## only if we haven't already
if ! defaults read com.apple.dock | grep -q Firefox.app;
then
 ## remove all from dock
 defaults write com.apple.dock persistent-apps -array

 DOCKITEMS=(
  Firefox
  "Google Chrome"
  iTerm
  Rambox
  Spotify
  Messages
  Calendar
  "System Preferences"
  "App Store"
  "MAMP PRO.app"
  "Sublime Text"
 )

 for app in "${DOCKITEMS[@]}"; do
   defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/${app}.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
 done
fi

##Restart Dock
killall Dock


## RUN A MACOS UPDATE
sudo softwareupdate --install -all

echo "Bootstrapping complete"

echo "Please Reboot"
