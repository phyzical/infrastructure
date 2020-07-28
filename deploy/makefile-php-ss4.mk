#!/bin/bash
# Makefile to handle deployments for ss4
# # php based site with database, assets and uploads
#

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(SELF_DIR)/makefile-common-silverstripe.mk

PROJECT_RSYNC_EXCLUDES= public/assets public/resources themes/simple public/output
PROJECT_RSYNC_INCLUDES = */vendor
WEBPACK_OUTPUT_DIR=/public/output/
WEBPACK_COPY_FOLDERS=
WEBPACK_PUBLIC_OUTPUT_PATH=$(WEBPACK_OUTPUT_DIR)


STAGING_PHP_VERSION=7.2
UAT_PHP_VERSION=7.2
PRODUCTION_PHP_VERSION=7.1
DEV_BUILD_FLUSH=true
COMPOSER_INSTALL=true
SAKE=./vendor/silverstripe/framework/sake

DB_NAME=$(SS_DATABASE_NAME)
DB_PARAMS=--user=$$SS_DATABASE_USERNAME \
			--password=$$SS_DATABASE_PASSWORD \
			--host=$$SS_DATABASE_SERVER \
			$$SS_DATABASE_NAME
DB_PARAMS_LITE_LOCAL=--user=$(SS_DATABASE_USERNAME) \
					--password=$(SS_DATABASE_PASSWORD) \
					--host=$(SS_DATABASE_SERVER)
DB_PARAMS_LOCAL= $(DB_PARAMS_LITE_LOCAL) \
				$(SS_DATABASE_NAME)
ENV_FILES=.env .env.test
SERVER_ROOT = /
ASSET_DIR=public/assets/
WEBPACK_BUILD=true
NPM_INSTALL=true

XDEBUG_FILE=/Applications/MAMP/bin/php/php7.2.1/lib/php/extensions/no-debug-non-zts-20170718/xdebug.so