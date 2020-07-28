#!/bin/bash
# Makefile to handle deployments for ss2
# # php based site with database, assets and uploads
#

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(SELF_DIR)/makefile-common-silverstripe.mk

PROJECT_RSYNC_EXCLUDES=assets themes/simple
PROJECT_RSYNC_INCLUDES = */vendor
ENV_FILES=.env
DEV_BUILD_FLUSH=true
COMPOSER_INSTALL=false
SAKE=./sapphire/sake
STAGING_PHP_VERSION=5.4
UAT_PHP_VERSION=5.4
PRODUCTION_PHP_VERSION=5.4
STAGING_POST_DEPLOY_COMMAND=echo "Forcing a Flush" && $(CURRENT_TARGET_SSH) 'rm -rf $(CURRENT_TARGET_PATH)/../../../tmp/$(CURRENT_TARGET_USER)/*'
UAT_POST_DEPLOY_COMMAND=echo "Forcing a Flush" && $(CURRENT_TARGET_SSH) 'rm -rf $(CURRENT_TARGET_PATH)/../../../tmp/$(CURRENT_TARGET_USER)/*'
PRODUCTION_POST_DEPLOY_COMMAND=echo "Forcing a Flush" && $(CURRENT_TARGET_SSH) 'rm -rf $(CURRENT_TARGET_PATH)/../tmp/silverstripe-cache*'
