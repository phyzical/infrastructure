#!/bin/bash
#
# Common npmy things
# # php based
#
SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(SELF_DIR)/makefile-common.mk

DOCKER_REPO_NAME=
IMAGE_NAME=
DOCKER_EXECUTABLE=docker
DOCKER_IMAGES=
build-and-send-all:
	make deploy-slack-notification DEPLOYMENT_MESSAGE="*Starting deployment of:*" TARGET_ENVIRONMENT=PRODUCTION;
	@$(foreach file, $(DOCKER_IMAGES), \
		make build-and-send-$(file); \
	)
	make deploy-slack-notification DEPLOYMENT_MESSAGE="*Finished deployment of:*" TARGET_ENVIRONMENT=PRODUCTION;

prune-images:
	${DOCKER_EXECUTABLE} image prune -a
build-image:
	cd ${IMAGE_NAME} && \
	${DOCKER_EXECUTABLE} build -t ${DOCKER_REPO_NAME}/${IMAGE_NAME} .
build-image-no-cache:
	cd ${IMAGE_NAME} && \
	${DOCKER_EXECUTABLE} build -t ${DOCKER_REPO_NAME}/${IMAGE_NAME} . --no-cache
send-image:
	${DOCKER_EXECUTABLE} push ${DOCKER_REPO_NAME}/${IMAGE_NAME}
test-image:
	${DOCKER_EXECUTABLE} run -ti ${DOCKER_REPO_NAME}/${IMAGE_NAME}