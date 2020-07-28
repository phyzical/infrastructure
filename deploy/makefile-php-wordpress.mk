#!/bin/bash
# Makefile to handle deployments for ss4
# # php based site with database, assets and uploads
#

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(SELF_DIR)/makefile-common.mk

ENV_FILES=.env
PROJECT_RSYNC_EXCLUDES= web
PROJECT_RSYNC_INCLUDES =
WEBPACK_OUTPUT_DIR=/web/output/
WEBPACK_PUBLIC_OUTPUT_PATH=/output/
WEBPACK_COPY_FOLDERS=
WEBPACK_PUBLIC_OUTPUT_PATH=$(WEBPACK_OUTPUT_DIR)

WEBPACK_CLEANUP=rm -rf public && ln -s web public
CURRENT_TARGET_POST_DEPLOY_COMMAND=$(CURRENT_TARGET_SSH) 'cd $(CURRENT_TARGET_PATH) &&  $(WEBPACK_CLEANUP)'
STAGING_PATH=/srv/users/$(STAGING_USER)/apps/$(STAGING_APP_NAME)
UAT_PATH=/srv/users/$(UAT_USER)/apps/$(UAT_APP_NAME)
PRODUCTION_PATH=var/www/$(STAGING_APP_NAME).com.au/web

STAGING_PHP_VERSION=7.2
UAT_PHP_VERSION=7.2
PRODUCTION_PHP_VERSION=7.1
DEV_BUILD_FLUSH=false
WEBPACK_BUILD=true
COMPOSER_INSTALL=true
NPM_INSTALL=true
SERVER_ROOT = /
ASSET_DIR=web/wp-content/uploads

DATABASE_REPLACE_REGEX='htt(p|ps):\/\/(\w|\-)+(\.(\w|\-)+)*(:[0-9]+)?\/?(\/[\w\.\-\/]*)*'
PRE_DATABASE_RESTORE_COMMAND=make restore-database-local
POST_LOCAL_DATABASE_RESTORE_COMMAND=	$(LOCAL_PHP_EXECUTABLE) /usr/local/bin/wp search-replace $(DATABASE_REPLACE_REGEX) '$(CURRENT_TARGET_SERVER_ALIAS)/$4' --regex --path=web && \
										make backup-database-local
