#!/bin/bash
# Makefile to handle deployments for ss3
# # php based site with database, assets and uploads
#

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(SELF_DIR)/makefile-common-silverstripe.mk

PROJECT_RSYNC_EXCLUDES= assets
PROJECT_RSYNC_INCLUDES = */vendor
WEBPACK_OUTPUT_DIR=/output/
WEBPACK_PUBLIC_OUTPUT_PATH=$(WEBPACK_OUTPUT_DIR)

ENV_FILES=.env
PHP_VERSION=5.6.32
STAGING_PHP_VERSION=5.6
UAT_PHP_VERSION=5.6
PRODUCTION_PHP_VERSION=5.6
PROJECT_RSYNC_EXCLUDES=themes/simple
DEV_BUILD_FLUSH=true
COMPOSER_INSTALL=false
NPM_INSTALL=false
PHPUNIT_FILE=vendor/phpunit/phpunit/phpunit.php
