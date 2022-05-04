#
# A makefile to handle any dev tool installations or setup targets
#
SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
DIR=$(PWD)

PC_NAME=
GIT_NAME=
GIT_EMAIL=

first-time-install-linux:
	make first-time-install-script-linux
	make setup-global-git-hook
	install-AWS-cli

first-time-install-osx:
	make first-time-install-script-osx
	make setup-global-git-hook
	install-AWS-cli

## Please populate .env form.env.example
first-time-install-script-osx:
	brew -v || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install
	@if [ "$(PC_NAME)" != "" ] || [ "$(GIT_NAME)" != "" ] || [ "$(GIT_EMAIL)" != "" ]; then \
		sudo chmod +x $(DIR)/scripts/OSXFirstTime.sh; \
		/bin/bash $(DIR)/scripts/OSXFirstTime.sh $(PC_NAME) $(GIT_NAME) $(GIT_EMAIL); \
	else \
		echo "Please provide PC_NAME GIT_NAME and GIT_EMAIL" \
	fi
first-time-install-script-linux:
	@if [ "$(PC_NAME)" != "" ]; then \
		sudo chmod +x $(DIR)/scripts/LinuxFirstTime.sh; \
		bash $(DIR)/scripts/LinuxFirstTime.sh $(PC_NAME) $(GIT_NAME) $(GIT_EMAIL); \
	fi

setup-global-git-hook:
	git config --global core.hooksPath $(DIR)/scripts/git-hooks/

install-AWS-cli:
	@if [ "$(IS_OSX)" = "true" ]; then \
		brew install awscli; \
	else \
		apt-get update && apt-get -y install awscli; \
	fi

install-composer:
	@if [ "$(IS_OSX)" = "true" ]; then \
		brew install composer; \
	else \
		curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
	fi

install-ansible:
	@if [ "$(IS_OSX)" = "true" ]; then \
		brew install ansible; \
	else \
		apt-get update && apt-get -y install ansible; \
	fi

-include ../.env
