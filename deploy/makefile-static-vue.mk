#!/bin/bash
#
# Common Makefile to handle deployments of headless vue apps
#
SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(SELF_DIR)/makefile-static.mk

ENV_FILES=.env .env.local .env.staging .env.uat .env.production
STAGING_BUCKET_NAME=$(PROJECT_NAME)-staging
UAT_BUCKET_NAME=$(PROJECT_NAME)-uat
PRODUCTION_BUCKET_NAME=$(PROJECT_NAME)-production
CURRENT_TARGET_BUCKET_NAME=$($(CURRENT_TARGET_ENVIRONMENT)_BUCKET_NAME)

STAGING_DISTRIBUTION_ID=
UAT_DISTRIBUTION_ID=
PRODUCTION_DISTRIBUTION_ID=
CURRENT_TARGET_DISTRIBUTION_ID=$($(CURRENT_TARGET_ENVIRONMENT)_DISTRIBUTION_ID)
S3_SOURCE_FOLDER=./dist
UPLOAD_WEBPACK_TO_S3=true
S3_STATEMENT='{ "Statement": [{ \
                        "Sid": "PublicReadGetObject", \
                        "Effect": "Allow", \
                        "Principal": { \
							"AWS": "*" \
						}, \
                        "Action": "s3:GetObject", \
                        "Resource": "arn:aws:s3:::$(CURRENT_TARGET_BUCKET_NAME)/*" \
                    }]}'
## TODO when this becomes refactored for rest of webpack to s3
## we shouldnt need to recheckout to builds in pipeline like we do localy hmmm
CURRENT_RSYNC_TASK=	cd builds/$(CURRENT_TARGET_ENVIRONMENT_LOWER)-source && \
					echo "installing node_modules" && \
					$(NPM_INSTALL_COMMAND) && \
					cd ../.. && \
					echo "Creating envs" && \
					$(foreach file, $(ENV_FILES), \
						make _single-env-decrypt ENV_FILE=builds/$(CURRENT_TARGET_ENVIRONMENT_LOWER)-source/$(file).encrypted && \
						mv builds/$(CURRENT_TARGET_ENVIRONMENT_LOWER)-source/$(file).encrypted builds/$(CURRENT_TARGET_ENVIRONMENT_LOWER)-source/$(file) && \
					) \
					cd builds/$(CURRENT_TARGET_ENVIRONMENT_LOWER)-source && \
					echo "Bundling webpack" && \
					$(CURRENT_TARGET_WEBPACK_BUILD_COMMAND) && \
					if [ ${UPLOAD_WEBPACK_TO_S3} = true ]; then \
						echo "Pulling and updating version" && \
						($(CURRENT_AWS_S3_COMMAND) mb s3://$(CURRENT_TARGET_BUCKET_NAME) || echo "") && \
						($(CURRENT_AWS_S3_COMMAND) cp s3://$(CURRENT_TARGET_BUCKET_NAME)/version.txt $(S3_SOURCE_FOLDER)/version.txt || echo "") && \
						echo $(CURRENT_TARGET_TAG) [ $(COMMIT) ] :: $(TIMESTAMP) by $(USER) | cat >> $(S3_SOURCE_FOLDER)/version.txt && \
						echo "sending bundle to s3" && \
						$(CURRENT_AWS_S3_COMMAND) sync --delete $(S3_SOURCE_FOLDER) s3://$(CURRENT_TARGET_BUCKET_NAME) $(RSYNC_INCLUDES_STRING) $(RSYNC_EXCLUDES_STRING) --cache-control max-age=2592000,public --expires 2034-01-01T00:00:00Z && \
						$(CURRENT_AWS_S3_COMMAND) cp $(S3_SOURCE_FOLDER)/index.html s3://$(CURRENT_TARGET_BUCKET_NAME)/index.html --cache-control max-age=1 && \
						$(CURRENT_AWS_S3_COMMAND) website s3://$(CURRENT_TARGET_BUCKET_NAME) --index-document index.html && \
						($(CURRENT_AWS_S3API_COMMAND) put-bucket-policy --bucket $(CURRENT_TARGET_BUCKET_NAME) --policy $(S3_STATEMENT) || echo "") && \
						$(CURRENT_AWS_S3API_COMMAND) put-bucket-website --bucket $(CURRENT_TARGET_BUCKET_NAME) --website-configuration $(S3_WEBSITE_CONFIG) && \
						echo "invalidating" && \
						$(CURRENT_AWS_COMMAND) cloudfront create-invalidation --distribution-id ${CURRENT_TARGET_DISTRIBUTION_ID} --paths "/*" && \
						echo "done"; \
					else \
						echo "rsyncing ${S3_SOURCE_FOLDER} to $(CURRENT_TARGET_USER)@$(CURRENT_TARGET_SERVER):$(CURRENT_TARGET_PATH)" && \
						rsync --stats --links --recursive $(RSYNC_INCLUDES_STRING) --delete $(RSYNC_EXCLUDES_STRING) -e ssh ${S3_SOURCE_FOLDER}/ $(CURRENT_TARGET_USER)@$(CURRENT_TARGET_SERVER):$(CURRENT_TARGET_PATH); \
					fi

WEBPACK_ENVS= export VUE_APP_SENTRY_RELEASE=$(SENTRY_RELEASE_ID_STRING)
WEBPACK_LIVE_COMMAND= $(WEBPACK_ENVS) && npm run build-$(CURRENT_TARGET_ENVIRONMENT_LOWER) && find . -name "*.map" -type f -delete
WEBPACK_DEV_COMMAND= $(WEBPACK_ENVS) && npm run serve

CURRENT_CLEANUP_TASK=echo ""
CURRENT_VERSION_TASK=echo ""
COMPOSER_INSTALL=false

run-dev-tools:
	make install-dev-tools; \
	vue-devtools &>/dev/null &

install-dev-tools:
	@echo "Checking for vue debugger"; \
	npm list -g @vue/devtools | grep devtools || npm install -g @vue/devtools

invalidate-cloudfront:
	$(CURRENT_AWS_COMMAND) cloudfront create-invalidation --distribution-id ${CURRENT_TARGET_DISTRIBUTION_ID} --paths "/*"
invalidate-cloudfront-staging:
	make invalidate-cloudfront TARGET_ENVIRONMENT=STAGING;
invalidate-cloudfront-uat:
	make invalidate-cloudfront TARGET_ENVIRONMENT=UAT;
invalidate-cloudfront-production:
	make invalidate-cloudfront TARGET_ENVIRONMENT=PRODUCTION;

S3_WEBSITE_CONFIG='{"IndexDocument": {"Suffix": "index.html"}, \
					"RoutingRules": [{	"Condition": {"HttpErrorCodeReturnedEquals": "404"}, \
										"Redirect": {"HostName": "$(CURRENT_TARGET_SERVER_ALIAS)","ReplaceKeyPrefixWith": "\#!"} \
									}] \
					}'