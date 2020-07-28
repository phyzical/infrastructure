#!/bin/bash
#
# Common Makefile to handle deployments
# # php based
#

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
PROJECT_REPO_DEPLOY_PATH=./
MAKEFLAGS += --no-print-directory
PROJECT_NAME=project
PROJECT_ROOT=$(shell pwd)
OS_PACKAGE_MANAGER=brew
IS_OSX=true
IS_LINUX=false
IS_WINDOWS=false

ENV_TO_USE=.env
TARGET_ENVIRONMENT=LOCAL
SENTRY_RELEASE_ID_STRING=$(PROJECT_NAME).$(TARGET_ENVIRONMENT).$(BRANCH).$(CURRENT_TARGET_TAG).$(COMMIT)
LOCAL_TAG=HEAD
HOMESTEAD_TAG=HEAD
STAGING_TAG=HEAD
UAT_TAG=v0.1
PRODUCTION_TAG=v0.1
BOWER_INSTALL=false
NPM_INSTALL=false
NPM_INSTALL_COMMAND=if [ ${NPM_INSTALL} = true ] && [ -f package.json ]; then \
						echo "Running npm install!!" && \
						if [ "$(TARGET_ENVIRONMENT)" = "LOCAL" ] || [ "$(TARGET_ENVIRONMENT)" = "HOMESTEAD" ]; then \
							npm i; \
						else \
							npm ci; \
						fi \
					fi
BOWER_INSTALL_COMMAND=if [ ${BOWER_INSTALL} = true ]; then \
						echo "Running bower install!!" && \
						bower install -P; \
					fi
DEV_BUILD_FLUSH=false
SAKE=./framework/sake
COMPOSER_INSTALL=false
DEBUG_OPTIONS= -dzend_extension=$(XDEBUG_FILE) \
	-dxdebug.remote_enable=1 \
	-dxdebug.remote_host=localhost \
	-dxdebug.remote_port=9000 \
	-dxdebug.remote_autostart=1 \
	-dxdebug.idekey=PHPSTORM \
	-dmemory_limit=2G
PHPUNIT_FILE=vendor/phpunit/phpunit/phpunit

DB_NAME=
DB_PARAMS=--user=$$DB_USERNAME \
			--password=$$DB_PASSWORD \
			--host=$$DB_HOST \
			$$DB_NAME
DB_PARAMS_LITE_LOCAL=--user=$(DB_USERNAME) \
					--password=$(DB_PASSWORD) \
					--host=$(DB_HOST)
DB_PARAMS_LOCAL=$(DB_PARAMS_LITE_LOCAL) \
			$(DB_NAME)
## Space-separated list of folders
## example XYZ XY
RSYNC_EXCLUDES = 	composer.phar \
					vendor \
					node_modules \
					stats \
					assets \
					infrastructure \
					bitbucket-pipelines.yml \
					storage\app \
					storage\framework \
					storage\logs \
					.env* \
					.user.ini \
					auth.json \
					robots.txt \
					*.log \
					.well-known \
					tests \
					test \
					$(PROJECT_RSYNC_EXCLUDES)
## example XYZ YZ
RSYNC_INCLUDES=$(PROJECT_RSYNC_INCLUDES)

RSYNC_EXCLUDES_STRING = $(foreach file,$(RSYNC_EXCLUDES),--exclude '$(file)')
RSYNC_INCLUDES_STRING = $(foreach file,$(RSYNC_INCLUDES),--include '$(file)')

TIMESTAMP=$(shell date +"%Y-%m-%d-%H-%M")
TIMESTAMPDATE=$(shell date +"%Y-%m-%d")
USER=$(shell git config user.name)
GIT_TAG = $(shell git describe | grep -o -e "[0-9a-z\.]*")
GIT_TAG_NUMBER = $(shell git describe | grep -o -E "[0-9|.]+")
COMMIT=$(shell git rev-parse --short HEAD)
BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
SAKE_COMMAND=
ASSET_DIR=assets/

WEBPACK_OUTPUT_DIR=/web/build/output/
WEBPACK_SRC_FOLDER=src
WEBPACK_COPY_FOLDERS=
WEBPACK_PUBLIC_OUTPUT_PATH=/web/build/output/
WEBPACK_DEV_SILENT=false
WEBPACK_ENVS=	"--env.outputDir=$(WEBPACK_OUTPUT_DIR) \
				--env.publicOutputPath=${WEBPACK_PUBLIC_OUTPUT_PATH}  \
				--env.foldersToCopy=$(WEBPACK_COPY_FOLDERS) \
				--env.releaseVersion=$(SENTRY_RELEASE_ID_STRING) \
				--env.silent=$(WEBPACK_DEV_SILENT)"
WEBPACK_BUILD=false
WEBPACK_DEV_COMMAND=WEBPACK_ENVS=$(WEBPACK_ENVS) npm run start
WEBPACK_LIVE_COMMAND=$(CURRENT_TARGET_ENV_COMMAND) && WEBPACK_ENVS=$(WEBPACK_ENVS) npm run build && find . -name "$(WEBPACK_OUTPUT_DIR)/*.map" -type f -delete

##### LOCAL START ######
LOCAL_SERVER=127.0.0.1
LOCAL_SERVER_ALIAS_PROTOCOL=http://
LOCAL_SERVER_ALIAS=$(PROJECT_NAME).localhost
LOCAL_ENV_COMMAND=echo "im default env command"
LOCAL_PHP_VERSION=${PHP_VERSION}
LOCAL_PHP_LOCATION=/Applications/MAMP/bin/php/php$(LOCAL_PHP_VERSION)/bin
LOCAL_PHP_EXECUTABLE=${LOCAL_PHP_LOCATION}/php
LOCAL_PHP_VERSION=${PHP_VERSION}
LOCAL_MYSQL_FOLDER=/Applications/MAMP/Library/bin/
LOCAL_COMPOSER_EXECUTABLE=/usr/local/bin/composer

##### STAGING START ######
STAGING_PHP_VERSION=5.4
STAGING_PHP_EXECUTABLE=php$(STAGING_PHP_VERSION)-sp
STAGING_PHP_LOCATION=/opt/sp/php$(STAGING_PHP_VERSION)/bin/
STAGING_USER=$(PROJECT_NAME)
STAGING_APP_NAME=$(PROJECT_NAME)
STAGING_SERVER=$(PROJECT_NAME).staging.strangeanimals.com.au
STAGING_SERVER_ALIAS_PROTOCOL=https://
STAGING_SERVER_ALIAS=$(STAGING_SERVER)
STAGING_USER_PATH=/srv/users/$(STAGING_USER)/
STAGING_PATH=/srv/users/$(STAGING_USER)/apps/$(STAGING_APP_NAME)/public/
STAGING_ENV_COMMAND=export `$(STAGING_PATH)/get-env.py -p $(STAGING_ENV_FILE)`
STAGING_ENV_FILE=/etc/php$(STAGING_PHP_VERSION)-sp/fpm-pools.d/$(STAGING_APP_NAME).d/settings.conf
STAGING_POST_DEPLOY_COMMAND=
STAGING_COMPOSER_EXECUTABLE=/opt/sp/bin/composer.phar
##### STAGING END ######

##### UAT START ######
UAT_PHP_VERSION=
UAT_PHP_EXECUTABLE=
UAT_PHP_LOCATION=
UAT_USER=$(PROJECT_NAME)
UAT_APP_NAME=$(PROJECT_NAME)
UAT_SERVER=
UAT_SERVER_ALIAS_PROTOCOL=https://
UAT_SERVER_ALIAS=$(UAT_SERVER)
UAT_USER_PATH=
UAT_PATH=
UAT_ENV_COMMAND=
UAT_ENV_FILE=
UAT_POST_DEPLOY_COMMAND=
UAT_COMPOSER_EXECUTABLE=
##### UAT END ######

##### PRODUCTION START ######
PRODUCTION_PHP_VERSION=
PRODUCTION_PHP_EXECUTABLE=
PRODUCTION_PHP_LOCATION=
PRODUCTION_USER=
PRODUCTION_APP_NAME=$(PROJECT_NAME)
PRODUCTION_SERVER=
PRODUCTION_SERVER_ALIAS=$(PRODUCTION_SERVER)
PRODUCTION_SERVER_ALIAS_PROTOCOL=https://
PRODUCTION_USER_PATH=
PRODUCTION_PATH=
PRODUCTION_ENV_COMMAND=
PRODUCTION_ENV_FILE=
PRODUCTION_POST_DEPLOY_COMMAND=
PRODUCTION_COMPOSER_EXECUTABLE=
##### PRODUCTION END ######

### CURRENT TARGET ####
CURRENT_TARGET_ENVIRONMENT_CHECK=if [ $(TARGET_ENVIRONMENT) != STAGING ] && [ $(TARGET_ENVIRONMENT) != UAT ] && [ $(TARGET_ENVIRONMENT) != PRODUCTION ] && [ $(TARGET_ENVIRONMENT) != LOCAL ] && [ $(TARGET_ENVIRONMENT) != HOMESTEAD ]; then \
								echo "Sorry you did not provide a valid environment TARGET_ENVIRONMENT=$(TARGET_ENVIRONMENT), (STAGING, UAT or PRODUCTION)"; \
								exit 1; \
							fi
CURRENT_TARGET_APP_NAME=$($(TARGET_ENVIRONMENT)_APP_NAME)
CURRENT_TARGET_ENVIRONMENT=$(TARGET_ENVIRONMENT)
CURRENT_TARGET_TAG=$($(CURRENT_TARGET_ENVIRONMENT)_TAG)
CURRENT_TARGET_ENVIRONMENT_LOWER:=$(shell echo $(CURRENT_TARGET_ENVIRONMENT) | tr A-Z a-z)
CURRENT_TARGET_USER=$($(CURRENT_TARGET_ENVIRONMENT)_USER)
CURRENT_TARGET_SERVER=$($(CURRENT_TARGET_ENVIRONMENT)_SERVER)
CURRENT_TARGET_SERVER_ALIAS_PROTOCOL=$($(CURRENT_TARGET_ENVIRONMENT)_SERVER_ALIAS_PROTOCOL)
CURRENT_TARGET_SERVER_ALIAS=$(CURRENT_TARGET_SERVER_ALIAS_PROTOCOL)$($(CURRENT_TARGET_ENVIRONMENT)_SERVER_ALIAS)
CURRENT_TARGET_SSH=ssh $(CURRENT_TARGET_USER)@$(CURRENT_TARGET_SERVER)
CURRENT_TARGET_SSH_C=ssh -C $(CURRENT_TARGET_USER)@$(CURRENT_TARGET_SERVER)
CURRENT_TARGET_SSH_T=ssh -t $(CURRENT_TARGET_USER)@$(CURRENT_TARGET_SERVER)
CURRENT_TARGET_PATH=$($(CURRENT_TARGET_ENVIRONMENT)_PATH)
CURRENT_TARGET_USER_PATH=$($(CURRENT_TARGET_ENVIRONMENT)_USER_PATH)
CURRENT_TARGET_ENV_COMMAND=$($(CURRENT_TARGET_ENVIRONMENT)_ENV_COMMAND)
CURRENT_TARGET_ENV_FILE=$($(CURRENT_TARGET_ENVIRONMENT)_ENV_FILE)
CURRENT_TARGET_PHP_VERSION=${$(CURRENT_TARGET_ENVIRONMENT)_PHP_VERSION}
CURRENT_TARGET_PHP_EXECUTABLE=${$(CURRENT_TARGET_ENVIRONMENT)_PHP_EXECUTABLE}
CURRENT_TARGET_PHP_LOCATION=${$(CURRENT_TARGET_ENVIRONMENT)_PHP_LOCATION}
CURRENT_TARGET_COMPOSER_INSTALL_COMMAND=make composer-install
CURRENT_TARGET_DEV_FLUSH_COMMAND=echo "placeholder"
CURRENT_TARGET_WEBPACK_BUILD_COMMAND=	if [ ${WEBPACK_BUILD} = true ]; then \
											echo "Webpack Rebuilding!!" && \
											$(WEBPACK_LIVE_COMMAND); \
										fi
CURRENT_TARGET_POST_DEPLOY_COMMAND=$($(CURRENT_TARGET_ENVIRONMENT)_POST_DEPLOY_COMMAND)
CURRENT_TARGET_SAKE_COMMAND=if [ ${DEV_BUILD_FLUSH} = true ] && [ ! -z "${SAKE_COMMAND}" ] && [ -f $(SAKE) ] && [ ! -z '${CURRENT_TARGET_PHP_LOCATION}' ]; then \
									echo "Custom Sake $(SAKE_COMMAND) Command Running!!" && \
									$(CURRENT_TARGET_ENV_COMMAND) && \
									env PATH="$(CURRENT_TARGET_PHP_LOCATION):$(PATH)" $(SAKE) $(SAKE_COMMAND); \
								fi
CURRENT_TARGET_COMPOSER_EXECUTABLE=${$(CURRENT_TARGET_ENVIRONMENT)_COMPOSER_EXECUTABLE}
CURRENT_TARGET_ASSET_DIR=$(CURRENT_TARGET_PATH)/$(ASSET_DIR)/
### END CURRENT TARGET ####

copy-env-file:
	echo "sending get-env.py";
	scp $(SELF_DIR)/../scripts/get-env.py $(CURRENT_TARGET_USER)@$(CURRENT_TARGET_SERVER):$(CURRENT_TARGET_PATH);
	$(CURRENT_TARGET_SSH) chmod +x $(CURRENT_TARGET_PATH)/get-env.py;

#################################
STAGING_COMMAND=$(CURRENT_TARGET_SSH) 'cd $(CURRENT_TARGET_PATH) && $(CURRENT_TARGET_ENV_COMMAND) && ${${COMMAND}}'
UAT_COMMAND=$(STAGING_COMMAND)
PRODUCTION_COMMAND=$(STAGING_COMMAND)
LOCAL_COMMAND=cd $(PROJECT_REPO_DEPLOY_PATH) && ${${COMMAND}}
HOMESTEAD_COMMAND=$(HOMESTEAD_SSH_COMMAND) -- -t 'cd $(HOMESTEAD_TARGET_PATH) && ${${COMMAND}}'
CURRENT_TARGET_COMMAND=$($(CURRENT_TARGET_ENVIRONMENT)_COMMAND)
execute-command:
	@make init;
	@echo "Executing ${COMMAND}: ($(${COMMAND})) for ${TARGET_ENVIRONMENT}\n";
	@$(CURRENT_TARGET_COMMAND);

## this comand requires duplication do to needing to run on in an ssh string and generic infra
COMPOSER_INSTALL_COMMAND=	if [ ${COMPOSER_INSTALL} = true ]; then \
								if [ $(CURRENT_TARGET_ENVIRONMENT) = LOCAL ] || [ $(CURRENT_TARGET_ENVIRONMENT) = HOMESTEAD ]; then \
									COMPOSER_MEMORY_LIMIT=${COMPOSER_MEMORY_LIMIT} ${CURRENT_TARGET_PHP_EXECUTABLE} ${CURRENT_TARGET_COMPOSER_EXECUTABLE} install --prefer-dist --verbose; \
								else \
									COMPOSER_MEMORY_LIMIT=${COMPOSER_MEMORY_LIMIT} ${CURRENT_TARGET_PHP_EXECUTABLE} ${CURRENT_TARGET_COMPOSER_EXECUTABLE} install --prefer-dist --no-dev --verbose; \
								fi\
							fi
# Call this to install dependencies based on composer.lock
composer-install:
	if [ $(CURRENT_TARGET_ENVIRONMENT) = LOCAL ] || [ $(CURRENT_TARGET_ENVIRONMENT) = HOMESTEAD ]; then \
		make composer ARG="install --prefer-dist"; \
	else \
		make composer ARG="install --prefer-dist --no-dev"; \
	fi \

# Call this to generate new composer.lock
composer-update:
	@make composer ARG=update COMPOSER_MEMORY_LIMIT=-1

# Call this to validate if composer.json matches composer.lock before committing composer.lock after an update.
# This ensures that users won't see the warning that composer.json is out of date.
composer-validate:
	@make composer ARG=validate

COMPOSER_MEMORY_LIMIT=
# used to be compser.phar

COMPOSER_COMMAND=if [ -f composer.json ]; then \
					COMPOSER_MEMORY_LIMIT=${COMPOSER_MEMORY_LIMIT} ${CURRENT_TARGET_PHP_EXECUTABLE} ${CURRENT_TARGET_COMPOSER_EXECUTABLE} $(ARG) --verbose; \
				fi

composer:
	@if [ $(COMPOSER_INSTALL) = true ]; then \
		make COMMAND=COMPOSER_COMMAND execute-command; \
	fi

NPM_COMMAND=	$(NPM_INSTALL_COMMAND)

npm:
	make COMMAND=NPM_COMMAND execute-command

npm-install:
	make create-npmrc
	make npm ARG='install'

npm-run:
	make npm ARG='run $(ARG)'

webpack-dev-silent:
	make webpack-dev WEBPACK_DEV_SILENT=true

webpack-dev:
	$(WEBPACK_DEV_COMMAND)

webpack-live:
	$(WEBPACK_LIVE_COMMAND)

RUN_STYLELINT=true
RUN_ESLINT=true
fix-linting:
	@if [ $(RUN_STYLELINT) = true ]; then \
		node_modules/.bin/stylelint --allow-empty-input --fix '$(WEBPACK_SRC_FOLDER)/**/*.css' '$(WEBPACK_SRC_FOLDER)/**/*.scss'; \
	fi;
	@if [ ${RUN_ESLINT} = true ]; then \
		node_modules/.bin/eslint --fix '$(WEBPACK_SRC_FOLDER)/**/*.js' '$(WEBPACK_SRC_FOLDER)/**/*.vue' --no-error-on-unmatched-pattern; \
	fi;

RESET_DEPENDENCIES_COMMAND= @echo "Removing: node_modules, vendor & package-lock.json"; \
							rm -rf node_modules vendor package-lock.json; \
							echo "Removed: node_modules, vendor & package-lock.json";
install-dependencies-fresh:
	${RESET_DEPENDENCIES_COMMAND}
	make install-dependencies
EXTRA_INSTALL_DEPENDENCIES=echo ""
ON_AFTER_INSTALL_DEPENDENCIES_COMMAND=echo ""
install-dependencies:
	make init-local-env
	make composer-install
	make npm-install
	$(EXTRA_INSTALL_DEPENDENCIES)
	${ON_AFTER_INSTALL_DEPENDENCIES_COMMAND}

init:
	@$(CURRENT_TARGET_ENVIRONMENT_CHECK)
	make init-local-env

user:
	@echo $(USER) $(BRANCH) [ $(COMMIT) ]

ssh-staging:
	make ssh TARGET_ENVIRONMENT=STAGING
ssh-uat:
	make ssh TARGET_ENVIRONMENT=UAT
ssh-production:
	make ssh TARGET_ENVIRONMENT=PRODUCTION
ssh:
	@make init
	$(CURRENT_TARGET_SSH_T) "cd $(CURRENT_TARGET_PATH);bash"

ssh-root-staging:
	make ssh-root TARGET_ENVIRONMENT=STAGING CURRENT_TARGET_USER="ubuntu"
ssh-root-uat:
	make ssh-root TARGET_ENVIRONMENT=UAT CURRENT_TARGET_USER="ubuntu"
ssh-root-production:
	make ssh-root TARGET_ENVIRONMENT=PRODUCTION CURRENT_TARGET_USER="ubuntu"
ssh-root:
	@make init
	$(CURRENT_TARGET_SSH)

TMP_LOCAL_ENV_VAR=/tmp/envsBeingUpdated.txt
edit-env-var-server:
	@make init;
	@echo "backing up env file";
	@$(CURRENT_TARGET_SSH) "cat $(CURRENT_TARGET_ENV_FILE)" > $(TMP_LOCAL_ENV_VAR);
	@nano $(TMP_LOCAL_ENV_VAR);
	@echo "pushing new env file and restarting FPM";
	@cat $(TMP_LOCAL_ENV_VAR) | $(CURRENT_TARGET_SSH) "sudo tee $(CURRENT_TARGET_ENV_FILE) && sudo service php$(CURRENT_TARGET_PHP_VERSION)-fpm-sp restart";
	@echo "removing tmp env file";
	@rm $(TMP_LOCAL_ENV_VAR);

edit-env-var-staging:
	make edit-env-var-server TARGET_ENVIRONMENT=STAGING CURRENT_TARGET_USER="ubuntu"
edit-env-var-uat:
	make edit-env-var-server TARGET_ENVIRONMENT=UAT CURRENT_TARGET_USER="ubuntu"

show-env-var-staging:
	@make show-env-var TARGET_ENVIRONMENT=STAGING
show-env-var-uat:
	@make show-env-var TARGET_ENVIRONMENT=UAT
show-env-var-production:
	@make show-env-var TARGET_ENVIRONMENT=PRODUCTION

show-env-var:
	@$(CURRENT_TARGET_SSH) \
	cat $(CURRENT_TARGET_ENV_FILE)

show-phpinfo-staging:
	@make show-phpinfo TARGET_ENVIRONMENT=STAGING
show-phpinfo-uat:
	@make show-phpinfo TARGET_ENVIRONMENT=UAT
show-phpinfo-production:
	@make show-phpinfo TARGET_ENVIRONMENT=PRODUCTION

INI_ARG_REGEX="upload_max_filesize|post_max_size|memory_limit|max_execution_time"
show-phpinfo:
	@echo ""
	@echo "Use make show-phpinfo-(environment) INI_ARG_REGEX=(your regex) to output custom values"
	@echo "--------------------------------------------------------------------------------------"
	@echo "Getting PHP INFO for $(CURRENT_TARGET_ENVIRONMENT)"

	@$(CURRENT_TARGET_SSH) '$(CURRENT_TARGET_PHP_EXECUTABLE) -r "phpinfo();" | egrep ${INI_ARG_REGEX}'

deploy-staging:
	make deploy-rsync TARGET_ENVIRONMENT=STAGING FORCE_DISABLE_ENV_DECRYPTION=true
deploy-uat:
	make deploy-rsync TARGET_ENVIRONMENT=UAT FORCE_DISABLE_ENV_DECRYPTION=true
deploy-production:
	make deploy-rsync TARGET_ENVIRONMENT=PRODUCTION FORCE_DISABLE_ENV_DECRYPTION=true
DEPLOYMENT_MESSAGE=
BONUS_MESSAGE=
FORCE_DEPLOY_SLACK_NOTIFICATION=FALSE
DAY_OF_WEEK=$(shell date '+%A')
WARNING_MESSAGE=\n *WARNING: ITS ${DAY_OF_WEEK}* \n *WARNING: ITS ${DAY_OF_WEEK}* \n *WARNING: ITS ${DAY_OF_WEEK}* \n https://media3.giphy.com/media/sTczweWUTxLqg/giphy.gif \n
deploy-slack-notification:
	@if [ $(CURRENT_TARGET_ENVIRONMENT) = PRODUCTION ] || [ $(FORCE_DEPLOY_SLACK_NOTIFICATION) = TRUE ]; then \
		if [ "${DAY_OF_WEEK}" = "Friday" ] || [ "${DAY_OF_WEEK}" = "Saturday" ] || [ "${DAY_OF_WEEK}" = "Sunday" ]; then \
			curl -X POST -H 'Content-type: application/json' --data '{"text":"${WARNING_MESSAGE}${DEPLOYMENT_MESSAGE} \n ${DEPLOYMENT_SLACK_MESSAGE} \n ${BONUS_MESSAGE}"}' ${DEPLOYMENT_SLACK_HOOK}; \
		else \
  		  	curl -X POST -H 'Content-type: application/json' --data '{"text":"${DEPLOYMENT_MESSAGE} \n ${DEPLOYMENT_SLACK_MESSAGE} \n ${BONUS_MESSAGE}"}' ${DEPLOYMENT_SLACK_HOOK}; \
		fi \
	fi

CURRENT_RSYNC_SOURCE_FOLDER=builds/$(CURRENT_TARGET_ENVIRONMENT_LOWER)-source/
CURRENT_RSYNC_TASK= echo "rsyncing ${CURRENT_RSYNC_SOURCE_FOLDER} to $(CURRENT_TARGET_USER)@$(CURRENT_TARGET_SERVER):$(CURRENT_TARGET_PATH)"; \
					rsync --stats --links --recursive $(RSYNC_INCLUDES_STRING) --delete $(RSYNC_EXCLUDES_STRING) -e ssh ${CURRENT_RSYNC_SOURCE_FOLDER} $(CURRENT_TARGET_USER)@$(CURRENT_TARGET_SERVER):$(CURRENT_TARGET_PATH);
PRE_RSYNC_TASK=
deploy-rsync:
	@make init
	@echo "Deploying present committed code to $(CURRENT_TARGET_ENVIRONMENT_LOWER) server via rsync..."
	@echo "recreating builds/$(CURRENT_TARGET_ENVIRONMENT_LOWER)-source/"
	@rm -fr builds/*
	@-mkdir -p builds/$(CURRENT_TARGET_ENVIRONMENT_LOWER)-source
	@echo "archiving $(CURRENT_TARGET_TAG):$(PROJECT_REPO_DEPLOY_PATH) to builds/$(PROJECT_NAME)-$(CURRENT_TARGET_ENVIRONMENT_LOWER).zip"
	git archive --format zip $(CURRENT_TARGET_TAG):$(PROJECT_REPO_DEPLOY_PATH) > builds/$(PROJECT_NAME)-$(CURRENT_TARGET_ENVIRONMENT_LOWER).zip
	@echo "unzip builds/$(PROJECT_NAME)-$(CURRENT_TARGET_ENVIRONMENT_LOWER).zip builds/$(CURRENT_TARGET_ENVIRONMENT_LOWER)-source"
	@unzip builds/$(PROJECT_NAME)-$(CURRENT_TARGET_ENVIRONMENT_LOWER).zip -d builds/$(CURRENT_TARGET_ENVIRONMENT_LOWER)-source
	@make deploy-slack-notification DEPLOYMENT_MESSAGE="*Starting deployment of:*"
	@$(PRE_RSYNC_TASK)
	@$(CURRENT_RSYNC_TASK)
	@make deploy-cleanup

CURRENT_CLEANUP_TASK=	rm -rf builds/*; \
						make copy-env-file; \
						$(CURRENT_TARGET_SSH) '		cd $(CURRENT_TARGET_PATH) && \
													$(COMPOSER_INSTALL_COMMAND) && \
													$(NPM_INSTALL_COMMAND) && \
													$(CURRENT_TARGET_WEBPACK_BUILD_COMMAND) && \
													$(CURRENT_TARGET_DEV_FLUSH_COMMAND);'
CURRENT_VERSION_TASK=	echo "updating versions on server"; \
						echo $(PROJECT_NAME) - $(CURRENT_TARGET_TAG) [ $(COMMIT) ] :: $(TIMESTAMP) by $(USER) | $(CURRENT_TARGET_SSH) 'cat >> ~/version.txt'

deploy-cleanup:
	@echo "removing builds/*"
	@$(CURRENT_CLEANUP_TASK)
	@$(CURRENT_VERSION_TASK)
	@echo "running post deploy command server"
	@$(CURRENT_TARGET_POST_DEPLOY_COMMAND)
	@make deploy-slack-notification DEPLOYMENT_MESSAGE="*Finished deployment of:*"
	@echo
	@echo ==================================================
	@echo $(CURRENT_TARGET_ENVIRONMENT_LOWER) Tag $(CURRENT_TARGET_TAG) released
	@echo
	@echo To login, point your browser at:
	@echo $(CURRENT_TARGET_SERVER) or $(CURRENT_TARGET_SERVER_ALIAS)
	@make open
	@echo ==================================================

restore-database-staging:
	make restore-database TARGET_ENVIRONMENT=STAGING
restore-database-uat:
	make restore-database TARGET_ENVIRONMENT=UAT
PRE_DATABASE_RESTORE_COMMAND=echo ""
POST_DATABASE_RESTORE_COMMAND=echo ""
restore-database:
	@make init;
	@$(PRE_DATABASE_RESTORE_COMMAND)
	@if [ $(CURRENT_TARGET_ENVIRONMENT) = STAGING ] || [ $(CURRENT_TARGET_ENVIRONMENT) = UAT ]; then \
		echo "Uploading db-backup/$(PROJECT_NAME).latest.mysql to $(CURRENT_TARGET_USER)@$(CURRENT_TARGET_SERVER):mysql-upload.mysql"; \
		scp -C db-backup/$(PROJECT_NAME).latest.mysql $(CURRENT_TARGET_USER)@$(CURRENT_TARGET_SERVER):mysql-upload.mysql; \
		make copy-env-file; \
		echo "Restoring mysql-upload.mysql on $(CURRENT_TARGET_SSH)"; \
		$(CURRENT_TARGET_SSH) \
			'$(CURRENT_TARGET_ENV_COMMAND) && \
			mysql $(DB_PARAMS) -e "DROP DATABASE $$DB_NAME; CREATE DATABASE $$DB_NAME;" && \
			mysql $(DB_PARAMS) < mysql-upload.mysql'; \
		$(POST_DATABASE_RESTORE_COMMAND); \
	else \
		echo "Sorry you did not provide a valid enviroment; $(CURRENT_TARGET_ENVIRONMENT)"; \
	fi

POST_LOCAL_DATABASE_RESTORE_COMMAND=echo "This is the default"
POST_LOCAL_DATABASE_REMAKE_COMMAND=echo "This is the default"
POST_LOCAL_DATABASE_RESET_COMMAND=echo "This is the default"
db-remake:
	@echo "Resetting ${DB_NAME} Database";
	@$(LOCAL_MYSQL_FOLDER)mysql $(DB_PARAMS_LITE_LOCAL) -e "DROP DATABASE ${DB_NAME};" || echo "";
	@$(LOCAL_MYSQL_FOLDER)mysql $(DB_PARAMS_LITE_LOCAL) -e "CREATE DATABASE ${DB_NAME};";
	$(POST_LOCAL_DATABASE_REMAKE_COMMAND)

db-reset:
	@make db-remake;
	@$(POST_LOCAL_DATABASE_RESET_COMMAND);

restore-database-local:
	@echo "ReCreating  ${DB_NAME} Database";
	@make db-remake;
	@echo "Restoring ->> $(PROJECT_NAME).latest.mysql on LOCAL";
	@$(LOCAL_MYSQL_FOLDER)mysql $(DB_PARAMS_LOCAL) < db-backup/$(PROJECT_NAME).latest.mysql && \
		echo "Restored local $(PROJECT_NAME)" \
		|| echo "\nError in mysql: Make sure DB_PARAMS are defined.\n"; \
	$(POST_LOCAL_DATABASE_RESTORE_COMMAND)

restore-assets-local:
	@echo "Copying assets to local..."
	@-mkdir -p $(ASSET_DIR)
	@cd $(ASSET_DIR) && cat ${PROJECT_ROOT}/assets-backup/assets.latest.tgz | gzip -d | tar zxvf -
	@echo "Restored assets to $(ASSET_DIR)"
	@echo "Done! Assets copied."

restore-assets-staging:
	make restore-assets TARGET_ENVIRONMENT=STAGING
restore-assets-uat:
	make restore-assets TARGET_ENVIRONMENT=UAT

restore-assets:
	@make init
	@du -sk  assets-backup/assets.latest.tgz | cut -f1 > size.txt
	@if [ $(CURRENT_TARGET_ENVIRONMENT)=STAGING ] || [ $(CURRENT_TARGET_ENVIRONMENT)=UAT ] ; then \
		echo "Creating assets folder on $(CURRENT_TARGET_SSH)" && \
		$(CURRENT_TARGET_SSH) mkdir -p $(CURRENT_TARGET_ASSET_DIR) && \
		echo "Uploading assets-backup/assets.latest.tgz to $(CURRENT_TARGET_ASSET_DIR)" && \
		cat assets-backup/assets.latest.tgz | pv -s $(shell echo $$(($(shell cat size.txt) * 1024))) | \
			$(CURRENT_TARGET_SSH) \
			"cd $(CURRENT_TARGET_ASSET_DIR); gzip -d | tar zxvf -"; \
	else \
		echo "Sorry you did not provide a valid enviroment; $(CURRENT_TARGET_ENVIRONMENT)"; \
	fi
	@-rm size.txt

backup-assets-local:
	@echo "Backing up local assets"
	@-mkdir -p assets-backup
	@tar -C $(ASSET_DIR) -cz . | gzip \
		> assets-backup/assets.$(TIMESTAMP).tgz
	@cp assets-backup/assets.$(TIMESTAMP).tgz assets-backup/assets.latest.tgz
	@echo "Done! Backed up local assets to assets-backup"

backup-assets-staging:
	make backup-assets TARGET_ENVIRONMENT=STAGING
backup-assets-uat:
	make backup-assets TARGET_ENVIRONMENT=UAT
backup-assets-production:
	make backup-assets TARGET_ENVIRONMENT=PRODUCTION
backup-assets:
	@make init
	@-mkdir assets-backup
	@echo "pulling down $(CURRENT_TARGET_SSH_C):$(CURRENT_TARGET_ASSET_DIR)"
	@-rm size.txt
	@$(CURRENT_TARGET_SSH_C) \
		"du -sb  ${CURRENT_TARGET_ASSET_DIR} | cut -f1" > size.txt
	@$(CURRENT_TARGET_SSH_C) \
		tar -C ${CURRENT_TARGET_ASSET_DIR} -czP . | pv -s $$(cat size.txt) | gzip \
		> assets-backup/assets_$(CURRENT_TARGET_ENVIRONMENT_LOWER).$(TIMESTAMP).tgz
	@echo "renaming assets_$(CURRENT_TARGET_ENVIRONMENT_LOWER).$(TIMESTAMP).tgz asset.latest.tgz"
	@cp assets-backup/assets_$(CURRENT_TARGET_ENVIRONMENT_LOWER).$(TIMESTAMP).tgz assets-backup/assets.latest.tgz
	@-rm size.txt

CAT_VERSION=cat ~/version.txt
TAIL_VERSION=tail -n 1 ~/version.txt

backup-database-staging:
	make backup-database TARGET_ENVIRONMENT=STAGING
backup-database-uat:
	make backup-database TARGET_ENVIRONMENT=UAT
backup-database-production:
	make backup-database TARGET_ENVIRONMENT=PRODUCTION

backup-database:
	@make init
	@-mkdir db-backup
	@make copy-env-file
	@echo "pulling down db-backup/$(PROJECT_NAME)_$(CURRENT_TARGET_ENVIRONMENT_LOWER).$(TIMESTAMP).mysql from $(CURRENT_TARGET_SSH_C)"
	@$(CURRENT_TARGET_SSH_C) \
		'$(CURRENT_TARGET_ENV_COMMAND) && \
		mysqldump $(DB_PARAMS)' \
		> db-backup/$(PROJECT_NAME)_$(CURRENT_TARGET_ENVIRONMENT_LOWER).$(TIMESTAMP).mysql
	@echo "renaming $(PROJECT_NAME)_$(CURRENT_TARGET_ENVIRONMENT_LOWER).$(TIMESTAMP).mysql $(PROJECT_NAME).latest.mysql"
	@cp db-backup/$(PROJECT_NAME)_$(CURRENT_TARGET_ENVIRONMENT_LOWER).$(TIMESTAMP).mysql db-backup/$(PROJECT_NAME).latest.mysql

backup-database-local:
	@-mkdir db-backup
	@$(LOCAL_MYSQL_FOLDER)mysqldump $(DB_PARAMS_LOCAL) > db-backup/$(PROJECT_NAME)_local.$(TIMESTAMP).mysql && \
		echo "renaming $(PROJECT_NAME)_local.$(TIMESTAMP).mysql to $(PROJECT_NAME).latest.mysql" && \
		cp db-backup/$(PROJECT_NAME)_local.$(TIMESTAMP).mysql db-backup/$(PROJECT_NAME).latest.mysql \
		|| echo "\nError in mysqldump: Make sure DB_PARAMS are defined.\n"

show-current-version-staging:
	make show-current-version TARGET_ENVIRONMENT=STAGING
show-current-version-uat:
	make show-current-version TARGET_ENVIRONMENT=UAT
show-current-version-production:
	make show-current-version TARGET_ENVIRONMENT=PRODUCTION

SHOW_CURRENT_VERSION_COMMAND=	@make init && \
								$(CURRENT_TARGET_SSH) \
									'$(TAIL_VERSION)'

show-current-version:
	$(SHOW_CURRENT_VERSION_COMMAND)

show-current-version-all:
	@echo
	@echo Checking Staging Version:
	make show-current-version TARGET_ENVIRONMENT=STAGING
	@echo
	@echo Checking UAT Version:
	make show-current-version TARGET_ENVIRONMENT=UAT
	@echo
	@echo Checking Production Version:
	make show-current-version TARGET_ENVIRONMENT=PRODUCTION
	@echo

show-all-versions-staging:
	make show-all-versions TARGET_ENVIRONMENT=STAGING
show-all-versions-uat:
	make show-all-versions TARGET_ENVIRONMENT=UAT
show-all-versions-production:
	make show-all-versions TARGET_ENVIRONMENT=PRODUCTION

show-all-versions:
	@make init
	@$(CURRENT_TARGET_SSH) \
		'$(CAT_VERSION)'

list-tags-local:
	@git tag --list -n9 --sort="version:refname"

# This will use .env.testing in the repo
TEST_COMMAND=${CURRENT_TARGET_PHP_EXECUTABLE} $(DEBUG_OPTIONS) ${PHPUNIT_FILE} ${${FILTER}}
FILTER_COMMAND=--filter $(TEST_CASE)

PRE_TEST_COMMAND=@echo "I am a holder for PRE_TEST_COMMAND"
FULL_TEST_COMMAND=make COMMAND=TEST_COMMAND IS_TESTING=true execute-command
POST_TEST_COMMAND=@echo "I am a holder for POST_TEST_COMMAND"

test:
	${PRE_TEST_COMMAND};
	$(FULL_TEST_COMMAND);
	${POST_TEST_COMMAND};

test-by-case:
	make test FILTER=FILTER_COMMAND

inject-common-envs:
	cat "$(SELF_DIR)/../.env" >> "$(PROJECT_REPO_DEPLOY_PATH)/.env"

ENV_FILES=.env .env.local

VAULT_PASSWORD_FILE=~/.vault-password.txt
FORCE_DISABLE_ENV_DECRYPTION=false
_init-local-env:
	@if [ $(FORCE_DISABLE_ENV_DECRYPTION) = false ]; then \
		if [ ! -f $(PROJECT_REPO_DEPLOY_PATH)/.env ]; then \
			if [ -f $(PROJECT_REPO_DEPLOY_PATH)/.env.encrypted ]; then \
				make decrypt-envs; \
			else \
				touch $(PROJECT_REPO_DEPLOY_PATH)/.env; \
				echo "Please update .env i just made for you!"; \
			fi \
		fi \
	fi
VAULT_PASSWORD=
_vault-init:
	@if [ ! -f $(VAULT_PASSWORD_FILE) ]; then \
		if [ "$(VAULT_PASSWORD)" ]; then \
			echo "$(VAULT_PASSWORD)" >> $(VAULT_PASSWORD_FILE); \
		else \
			echo "please create $(VAULT_PASSWORD_FILE)"; \
		fi; \
	fi

_single-env-encrypt:
	make vault-command ENV_FILE=$(ENV_FILE) COMMAND=encrypt;

_single-env-decrypt:
	make vault-command ENV_FILE=$(ENV_FILE) COMMAND=decrypt;

decrypt-envs:
	@$(foreach file, $(ENV_FILES), \
		cp $(PROJECT_REPO_DEPLOY_PATH)/$(file).encrypted $(PROJECT_REPO_DEPLOY_PATH)/$(file).tmp && \
		cp $(PROJECT_REPO_DEPLOY_PATH)/$(file) $(PROJECT_REPO_DEPLOY_PATH)/$(file).old.$(TIMESTAMP) 2>/dev/null || : && \
		make _single-env-decrypt ENV_FILE=$(PROJECT_REPO_DEPLOY_PATH)/$(file).tmp && \
		mv $(PROJECT_REPO_DEPLOY_PATH)/$(file).tmp $(PROJECT_REPO_DEPLOY_PATH)/$(file); \
	)

encrypt-envs:
	@$(foreach file, $(ENV_FILES), \
		cp $(PROJECT_REPO_DEPLOY_PATH)/$(file) $(PROJECT_REPO_DEPLOY_PATH)/$(file).encrypted && \
		make _single-env-encrypt ENV_FILE=$(PROJECT_REPO_DEPLOY_PATH)/$(file).encrypted; \
	)

vault-command:
	@if [ "$(ENV_FILE)" = "" ]; then \
		echo "Please provide ENV_FILE to be encrypted"; \
	else \
		make _vault-init; \
		ansible-vault $(COMMAND) $(ENV_FILE) --vault-password-file=$(VAULT_PASSWORD_FILE); \
	fi

CURRENT_AWS_ACCESS_KEY_ID=$($(CURRENT_TARGET_ENVIRONMENT)_AWS_ACCESS_KEY_ID)
CURRENT_AWS_SECRET_ACCESS_KEY=$($(CURRENT_TARGET_ENVIRONMENT)_AWS_SECRET_ACCESS_KEY)
CURRENT_AWS_URL=$($(CURRENT_TARGET_ENVIRONMENT)_AWS_URL)
CURRENT_AWS_BUCKET=$($(CURRENT_TARGET_ENVIRONMENT)_AWS_BUCKET)
AWS_COMMAND_EXECUTABLE=AWS_PAGER="" aws
CURRENT_AWS_REGION=ap-southeast-2
CURRENT_AWS_COMMAND=AWS_ACCESS_KEY_ID=$(CURRENT_AWS_ACCESS_KEY_ID) AWS_SECRET_ACCESS_KEY=$(CURRENT_AWS_SECRET_ACCESS_KEY) ${AWS_COMMAND_EXECUTABLE} --region ${CURRENT_AWS_REGION}
CURRENT_AWS_S3_COMMAND=${CURRENT_AWS_COMMAND} --endpoint-url $(CURRENT_AWS_URL) s3
CURRENT_AWS_S3API_COMMAND=${CURRENT_AWS_COMMAND} --endpoint-url $(CURRENT_AWS_URL) s3api
UPLOAD_WEBPACK_TO_S3=false
S3_RESET_COMMAND=$(CURRENT_AWS_S3_COMMAND) mb s3://$(CURRENT_AWS_BUCKET); \
				$(CURRENT_AWS_S3_COMMAND) rb s3://$(CURRENT_AWS_BUCKET) --force; \
				$(CURRENT_AWS_S3_COMMAND) mb s3://$(CURRENT_AWS_BUCKET)
S3_ENABLED=false
s3-reset:
	@if [ "${S3_ENABLED}" = "true" ] ; then \
		$(S3_RESET_COMMAND); \
	fi

backup-s3:
	@-rm -rf s3-backup/$(PROJECT_NAME)_$(CURRENT_TARGET_ENVIRONMENT_LOWER).$(TIMESTAMPDATE)
	@-mkdir s3-backup/$(PROJECT_NAME)_$(CURRENT_TARGET_ENVIRONMENT_LOWER).$(TIMESTAMPDATE)
	@echo "pulling down s3-backup/$(PROJECT_NAME)_$(CURRENT_TARGET_ENVIRONMENT_LOWER).$(TIMESTAMPDATE) from s3://$(CURRENT_AWS_BUCKET)"
	$(CURRENT_AWS_S3_COMMAND) sync s3://$(CURRENT_AWS_BUCKET) ./s3-backup/$(PROJECT_NAME)_$(CURRENT_TARGET_ENVIRONMENT_LOWER).$(TIMESTAMPDATE)/
	@echo "renaming $(PROJECT_NAME)_$(CURRENT_TARGET_ENVIRONMENT_LOWER).$(TIMESTAMPDATE) $(PROJECT_NAME).latest"
	@-rm -rf s3-backup/$(PROJECT_NAME).latest
	@-mkdir s3-backup/$(PROJECT_NAME).latest
	@rsync -r s3-backup/$(PROJECT_NAME)_$(CURRENT_TARGET_ENVIRONMENT_LOWER).$(TIMESTAMPDATE)/ s3-backup/$(PROJECT_NAME).latest/
backup-s3-staging:
	make backup-s3 TARGET_ENVIRONMENT='STAGING'
backup-s3-uat:
	make backup-s3 TARGET_ENVIRONMENT='UAT'
backup-s3-production:
	make backup-s3 TARGET_ENVIRONMENT='PRODUCTION'

restore-s3:
	@echo "creating bucket s3://$(CURRENT_AWS_BUCKET)"
	@$(CURRENT_AWS_S3_COMMAND) mb s3://$(CURRENT_AWS_BUCKET) | echo;
	@echo "pushing up s3 files in s3-backup/$(PROJECT_NAME).latest"
	$(CURRENT_AWS_S3_COMMAND) sync ./s3-backup/$(PROJECT_NAME).latest/ s3://$(CURRENT_AWS_BUCKET) --delete
restore-s3-staging:
	make restore-s3 TARGET_ENVIRONMENT='STAGING'
restore-s3-uat:
	make restore-s3 TARGET_ENVIRONMENT='UAT'
restore-s3-production:
	make restore-s3 TARGET_ENVIRONMENT='PRODUCTION'
RUN_OPEN=true
OPEN_COMMAND=open
open:
	@if [ ${RUN_OPEN} = true ]; then \
		if echo "$(CURRENT_TARGET_SERVER_ALIAS)" | grep -q "http"; then \
			${OPEN_COMMAND} $(CURRENT_TARGET_SERVER_ALIAS) | echo ""; \
		else \
			${OPEN_COMMAND} http://$(CURRENT_TARGET_SERVER_ALIAS) | echo ""; \
		fi \
	fi
open-staging:
	make open TARGET_ENVIRONMENT='STAGING'
open-uat:
	make open TARGET_ENVIRONMENT='UAT'
open-production:
	make open TARGET_ENVIRONMENT='PRODUCTION'

VERSION_TYPE=DEFAULT
VERSION_BRANCH_CHECK=if [ $(VERSION_TYPE) = minor ] || [ $(VERSION_TYPE) = major ]; then \
						if [ $(BRANCH) != master ]; then \
							echo "Please checkout (master) not ($(BRANCH))" && exit 1; \
						fi; \
					else \
						if [[ $(BRANCH) != *"hotfix/"* ]]; then \
							echo "Please checkout a 'hotfix/BLAH' branch not ($(BRANCH))" && exit 1; \
						fi; \
					fi
_bump-version:
	@${VERSION_BRANCH_CHECK}
	@echo "git pushing to make sure you are up to date!"
	git push
	@echo "Commiting new version (${VERSION_TYPE}) and creating tag!"
	@npm version ${VERSION_TYPE}
	@echo "Gitty McPusher says: \n Dont forget to push the tag!"
bump-version-patch:
	make bump-version VERSION_TYPE=patch
bump-version-minor:
	make bump-version VERSION_TYPE=minor
bump-version-major:
	make bump-version VERSION_TYPE=major

PUBLISH_COMMAND=echo "Git pushing version change" && \
				git push && \
				echo "Git pushing tags" && \
				git push --tags
VERSION_COMMAND=make bump-version-${VERSION_TYPE}

_bump-version-and-publish:
	@echo "Running Version Command";
	@${VERSION_COMMAND}
	@echo "Running Publish Command";
	@${PUBLISH_COMMAND}

bump-hotfix-and-publish:
	make bump-version-and-publish VERSION_TYPE=patch
bump-minor-and-publish:
	make bump-version-and-publish VERSION_TYPE=minor
bump-major-and-publish:
	make bump-version-and-publish VERSION_TYPE=major

DEPLOYMENT_SLACK_HOOK=
DEPLOYMENT_PIPELINE_LINK=
DEPLOYMENT_SLACK_MESSAGE=*${PROJECT_NAME}* \n ${CURRENT_TARGET_TAG} \n ${CURRENT_TARGET_SERVER_ALIAS} \n ${DEPLOYMENT_PIPELINE_LINK}

-include $(SELF_DIR)/../../overrides.mk
