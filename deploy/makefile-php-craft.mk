#!/bin/bash
# Makefile to handle deployments
# # php based site with database, assets and uploads
#

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(SELF_DIR)/makefile-common.mk

WEBPACK_CLEANUP=rm -rf public && ln -s web public
WEBPACK_PUBLIC_OUTPUT_PATH=/build/output/

PROJECT_RSYNC_EXCLUDES=public web/build/output
CURRENT_TARGET_POST_DEPLOY_COMMAND=$(CURRENT_TARGET_SSH) 'cd $(CURRENT_TARGET_PATH) &&  $(WEBPACK_CLEANUP)'
WEBPACK_BUILD=true
STAGING_PATH=/srv/users/$(STAGING_USER)/apps/$(STAGING_APP_NAME)/
UAT_PATH=/srv/users/$(UAT_USER)/apps/$(UAT_APP_NAME)/
PRODUCTION_PATH=var/www/$(STAGING_APP_NAME).com.au/web
ASSET_DIR=web/assets/
COMPOSER_INSTALL=true
NPM_INSTALL=true
STAGING_PHP_VERSION=7.1
UAT_PHP_VERSION=7.1
PRODUCTION_PHP_VERSION=7.1
ENV_FILES=.env
SERVER_ROOT = /
DB_NAME = DB
DB_USERNAME = root
DB_PASSWORD = \#rtDev10
DB_HOST = localhost
IS_TESTING = false

DB_NAME=$(CRAFTENV_DB_DATABASE)
DB_PARAMS=--user=$$CRAFTENV_DB_USER \
			--password=$$CRAFTENV_DB_PASSWORD \
			--host=$$CRAFTENV_DB_SERVER \
			$$CRAFTENV_DB_DATABASE
DB_PARAMS_LITE_LOCAL=--user=$(CRAFTENV_DB_USER) \
					--password=$(CRAFTENV_DB_PASSWORD) \
					--host=$(CRAFTENV_DB_SERVER)
DB_PARAMS_LOCAL= $(DB_PARAMS_LITE_LOCAL) \
			$(CRAFTENV_DB_DATABASE)
TIMESTAMP=$(shell date +"%Y-%m-%d-%H:%M")

