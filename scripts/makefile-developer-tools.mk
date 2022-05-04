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
	@if [ "$(PC_NAME)" != "" ]; then \
		sudo chmod +x $(DIR)/scripts/LinuxFirstTime.sh; \
		bash $(DIR)/scripts/LinuxFirstTime.sh $(PC_NAME) $(GIT_NAME) $(GIT_EMAIL); \
	fi

first-time-install-osx:
	@if [ "$(which brew)" != "" ]; then \
		curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install >> brew-install.sh; \
		chmod +x brew-install.sh; \
		./brew-install.sh; \
		rm ./brew-install.sh; \
	fi;
	@if [ "$(PC_NAME)" != "" ] || [ "$(GIT_NAME)" != "" ] || [ "$(GIT_EMAIL)" != "" ]; then \
		sudo chmod +x $(DIR)/scripts/OSXFirstTime.sh; \
		. $(DIR)/scripts/OSXFirstTime.sh $(PC_NAME) $(GIT_NAME) $(GIT_EMAIL); \
	else \
		echo "Please provide PC_NAME GIT_NAME and GIT_EMAIL"; \
	fi

-include ../.env
