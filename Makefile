#
# A makefile to handle any dev tool installations or setup targets
#
-include .env
include scripts/makefile-developer-tools.mk
include deploy/makefile-common.mk

PROJECT_NAME=infrastructure

update-show-submitter:
	cd scripts/unraid/showSubmitter && \
	npm update

test-show-submitter:
	cd scripts/unraid/showSubmitter && \
	npm run test

build-show-submitter:
	cd scripts/unraid/showSubmitter && \
	npm install && \
	npm run build

run-spotify-scraper:
	bash ./scripts/unraid/spotifyScraper.sh


run-webhook-manager:
	bash ./scripts/webhook_manager.sh ${GITHUB_TOKEN} ${GITHUB_DISCORD_WEBHOOK_URL}
