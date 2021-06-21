#
# A makefile to handle any dev tool installations or setup targets
#
include scripts/makefile-developer-tools.mk
include deploy/makefile-common.mk

PROJECT_NAME=infrastructure

build-show-submitter:
	cd scripts/unraid/showSubmitter && \
	npm install && \
	npm run build

run-spotify-scraper:
	bash ./scripts/unraid/spotifyScraper.sh
