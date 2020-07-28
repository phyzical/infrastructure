#!/bin/bash
# Makefile to handle deployments for static sites
# # just webpakc to ahndle assets
#

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(SELF_DIR)/makefile-common.mk

WEBPACK_BUILD=true
NPM_INSTALL=true
PROJECT_RSYNC_EXCLUDES=public web/build/output
ENV_FILES=.env