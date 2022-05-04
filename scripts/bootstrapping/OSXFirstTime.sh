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


echo "Installing cask..."

CASKS=(
    aws-vault
    firefox
    gitup
    google-chrome
    rectangle
    discord
    whatsapp
    slack
    sublime-text
    spotify
    tunnelblick
    thunderbird
    vagrant
    virtualbox
    vlc
    visual-studio-code
)

echo "Installing cask apps..."
brew cask install ${CASKS[@]}

PACKAGES=(
    ansible
    awscli
    git
    hashicorp/tap/terraform-ls
    hub
    markdown
    memcached
    np
    mysql
    rabbitmq
    rename
    ssh-copy-id
    wget
    geoip
    nmap
    unrar
    terraform
)

echo "Installing packages..."
brew install ${PACKAGES[@]}

echo "Cleaning up..."
brew cleanup

if ! -e "~/.profile"; then
 cat ./.profile > ~/.profile
fi

if ! -e "~/.zshrc"; then
 cat ./.zshrc > ~/.zshrc
fi

if ! git config --list | grep -q "user.name"; then
 git config --global user.name $2
 git config --global user.email $3
 git config --global core.editor "nano" 
fi

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

# hide siri
defaults write com.apple.systemuiserver "NSStatusItem Visible Siri" -bool false

## only if we haven't already
if ! defaults read com.apple.dock | grep -q Firefox.app;
then
 ## remove all from dock
 defaults write com.apple.dock persistent-apps -array

 DOCKITEMS=(
  Firefox
  Terminal
  Slack
  Discord
  Spotify
  WhatsApp
  Calendar
  "System Preferences"
  "App Store"
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

echo "Please scan output for errors then reboot if none"
