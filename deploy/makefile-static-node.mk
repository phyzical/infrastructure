#!/bin/bash
#
# Common Makefile to handle deployments of headless vue apps
#
SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(SELF_DIR)/makefile-static.mk

ENV_FILES=.env
DOCKER_PORT=3000
NPM_INSTALL=false
WEBPACK_DEV_COMMAND=docker stop $(PROJECT_NAME)-$(CURRENT_TARGET_ENVIRONMENT); \
				docker build -t phyzical/nodejs . && \
				docker run  --rm --name $(PROJECT_NAME)-$(CURRENT_TARGET_ENVIRONMENT) -p $(DOCKER_PORT):$(DOCKER_PORT) -d phyzical/nodejs
WEBPACK_LIVE_COMMAND=$(WEBPACK_DEV_COMMAND)

kill:
	docker stop $(PROJECT_NAME)-$(CURRENT_TARGET_ENVIRONMENT)
