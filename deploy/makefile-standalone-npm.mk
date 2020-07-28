#!/bin/bash
#
# Common npmy things
# # php based
#
SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(SELF_DIR)/makefile-common.mk

NPM_INSTALL=true
npm-publish:
	make deploy-slack-notification DEPLOYMENT_MESSAGE="*Starting deployment of:*" TARGET_ENVIRONMENT=PRODUCTION
	npm publish
	make deploy-slack-notification DEPLOYMENT_MESSAGE="*Finished deployment of:*" TARGET_ENVIRONMENT=PRODUCTION

npm-unpublish:
	npm unpublish --force

npm-login:
	npm login

npm-token-create:
	echo "are you sure? ctrl+c to cancel"
	read yn
	npm token create --read-only