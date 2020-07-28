#!/bin/bash
# Makefile to handle deployments for laravel
#

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(SELF_DIR)/makefile-common.mk

DEV_BUILD_FLUSH=true
COMPOSER_INSTALL=true
NPM_INSTALL=true
PROJECT_REPO_DEPLOY_PATH=server
STAGING_PHP_VERSION=7.2
UAT_PHP_VERSION=7.2
STAGING_PATH=/srv/users/$(STAGING_USER)/apps/$(STAGING_APP_NAME)/
UAT_PATH=/srv/users/$(UAT_USER)/apps/$(UAT_APP_NAME)/
# Rebuild node-sass needs to be run when binding current env to nodejs.
# It does not need to be run everytime.
REBUILD_NODE_SASS=true
ENV_FILES=.env .env.testing

DB_NAME=$(DB_DATABASE)
DB_PARAMS=	--user=$$DB_USERNAME \
			--password=$$DB_PASSWORD \
			--host=$$DB_HOST \
			$$DB_DATABASE
DB_PARAMS_LITE_LOCAL=--user=$(DB_USERNAME) \
					--password=$(DB_PASSWORD) \
					--host=$(IP)
DB_PARAMS_LOCAL= $(DB_PARAMS_LITE_LOCAL) \
				$(DB_DATABASE)
TARGET_ENVIRONMENT=HOMESTEAD

RSYNC_INCLUDES=resources/views/vendor \
				$(PROJECT_RSYNC_INCLUDES)

RSYNC_EXCLUDES = 	composer.phar \
					vendor \
					node_modules \
					stats \
					assets \
					storage/*.key \
					storage/app/public/* \
					storage/framework \
					storage/logs \
					storage/cache \
					storage/sessions \
					storage/views \
					.env* \
					auth.json \
					$(PROJECT_RSYNC_EXCLUDES)

CURRENT_TARGET_DEV_FLUSH_COMMAND=if [ ${DEV_BUILD_FLUSH} = true ] && [ ! -z '${CURRENT_TARGET_PHP_LOCATION}' ]; then \
									${BUILD_COMMAND} && \
									${FLUSH_COMMAND}; \
								fi
BUILD_COMMAND=$(CURRENT_TARGET_ENV_COMMAND) && echo "$(DB_NAME)" && \
			  $(CURRENT_TARGET_PHP_EXECUTABLE) artisan migrate --force
FLUSH_COMMAND=${REBUILD_SASS_COMMAND} && \
				${NPM_INSTALL_COMMAND} && \
				${NPM_RUN_COMMAND} && \
				${CLEAR_COMMAND} && \
				${NOVA_COMMAND} && \
				${STORAGE_LINK_COMMAND} && \
				if [ $(SHOULD_SET_PASSPORT_KEYS) = true ]; then \
					$(PASSPORT_SET_KEY_LENGTH_COMMAND); \
				fi
REBUILD_SASS_COMMAND=if [ $(REBUILD_NODE_SASS) ]; then \
						npm rebuild node-sass; \
					fi
NPM_RUN_COMMAND=npm run production
OVERRIDE_ENV=
CLEAR_COMMAND=$(CURRENT_TARGET_PHP_EXECUTABLE) artisan cache:clear && \
				$(CURRENT_TARGET_PHP_EXECUTABLE) artisan config:clear  && \
				$(CURRENT_TARGET_PHP_EXECUTABLE) artisan clear-compiled && \
				$(CURRENT_TARGET_PHP_EXECUTABLE) artisan optimize && \
				$(CURRENT_TARGET_PHP_EXECUTABLE) artisan config:cache && \
				$(COMPOSER_AUTOLOAD_COMMAND) && \
				$(CURRENT_TARGET_PHP_EXECUTABLE) artisan config:clear

COMPOSER_AUTOLOAD_COMMAND=$(CURRENT_TARGET_PHP_EXECUTABLE) ${CURRENT_TARGET_COMPOSER_EXECUTABLE} dump-autoload

STORAGE_LINK_COMMAND=if [ -L "public/storage" ]; then \
                        rm public/storage; \
                    fi && \
                    $(CURRENT_TARGET_PHP_EXECUTABLE) artisan storage:link

NOVA_COMMAND=if [ ! -f "app/Nova/User.php" ]; then \
				$(CURRENT_TARGET_PHP_EXECUTABLE) artisan nova:install && \
				$(CURRENT_TARGET_PHP_EXECUTABLE) artisan migrate; \
			fi && \
			$(CURRENT_TARGET_PHP_EXECUTABLE) artisan nova:publish && \
			$(CURRENT_TARGET_PHP_EXECUTABLE) artisan view:clear
COPY_ENV_COMMAND=if [ ! -f ".env" ]; then \
					cp .env.example .env; \
				fi
ARTISAN_COMMAND=${CURRENT_TARGET_PHP_EXECUTABLE} artisan ${ARG}

WEBPACK_LIVE_COMMAND=cd server; \
					npm run production

WEBPACK_DEV_COMMAND=cd server && npm run watch

ARG=

SHOULD_SET_PASSPORT_KEYS=false
PASSPORT_SET_KEY_LENGTH_COMMAND=echo "Setting length of passport keys to 512.." && \
	$(CURRENT_TARGET_PHP_EXECUTABLE) artisan passport:keys  --length=512 --force

PRE_TEST_COMMAND=make config-cache OVERRIDE_ENV="--env=testing"
POST_TEST_COMMAND=make config-cache
###### Callable targets ######
# These only work when TARGET_ENVIRONMENT is LOCAL or HOMESTEAD

php-artisan:
	make COMMAND=ARTISAN_COMMAND execute-command

php-artisan-staging:
	make php-artisan TARGET_ENVIRONMENT=STAGING

php-artisan-uat:
	make php-artisan TARGET_ENVIRONMENT=UAT

php-artisan-production:
	make php-artisan TARGET_ENVIRONMENT=PRODUCTION

build:
	echo "Executing build... \n"
	make COMMAND=BUILD_COMMAND execute-command

flush:
	make COMMAND=FLUSH_COMMAND execute-command

nova-install:
	make COMMAND=NOVA_COMMAND execute-command

clear:
	make COMMAND=CLEAR_COMMAND execute-command

route-list:
	make php-artisan ARG=route:list

key-generate:
	make COMMAND=COPY_ENV_COMMAND execute-command
	make php-artisan ARG=key:generate
	make php-artisan ARG=config:cache

migrate-create:
	make php-artisan ARG="make:migration ${NAME}"

migrate-rollback:
	make php-artisan ARG=migrate:rollback

migrate:
	make php-artisan ARG=migrate

migrate-fresh:
	@if [ $(TARGET_ENVIRONMENT) != PRODUCTION ]; then \
		make php-artisan ARG=migrate:fresh; \
	fi

db-seed:
	@if [ $(TARGET_ENVIRONMENT) != PRODUCTION ]; then \
		make php-artisan ARG=db:seed; \
	fi

config-cache:
	make php-artisan ARG="config:cache ${OVERRIDE_ENV}"

storage-link:
	make COMMAND=STORAGE_LINK_COMMAND execute-command

db-rollback:
	make php-artisan ARG=migrate:rollback

composer-autoload:
	make COMMAND=COMPOSER_AUTOLOAD_COMMAND execute-command

POST_LOCAL_DATABASE_RESTORE_COMMAND=make migrate
POST_LOCAL_DATABASE_RESET_COMMAND=make composer-autoload && \
									make s3-reset && \
									if [ "${IS_TESTING}" != "true" ] ; then \
										make config-cache; \
									else \
										make config-cache OVERRIDE_ENV="--env=testing"; \
									fi && \
									make migrate-fresh && \
									make db-seed && \
									make clear
#refer to https://github.com/DarkaOnLine/L5-Swagger or see joe :)
generate-api-docs:
	make php-artisan ARG='vendor:publish --provider "L5Swagger\L5SwaggerServiceProvider"'
	make php-artisan ARG='l5-swagger:generate --all'

###### Local machine targets ######
start-server:
	@make php-artisan ARG=serve TARGET_ENVIRONMENT=LOCAL


###### Vagrant targets ######
homestead-ssh:
	$(HOMESTEAD_SSH_COMMAND)

RESTART_FPM_COMMAND=sudo service php$(HOMESTEAD_PHP_VERSION)-fpm restart

homestead-reload-env:
	@if [ $(TARGET_ENVIRONMENT) = HOMESTEAD ]; then \
		make COMMAND=RESTART_FPM_COMMAND CURRENT_TARGET_PHP_EXECUTABLE=${HOMESTEAD_PHP} execute-command; \
	fi

fresh-box:
	! make homestead-box
	make homestead

clean:
	-rm -rf vp

homestead:
	@if [ -d "homestead" ] ; \
	then \
		echo "homestead already exists!"; \
		make homestead-init;  \
	else \
		git clone https://github.com/laravel/homestead.git && \
		cd homestead && \
		git checkout $(HOMESTEAD_TAG) && \
		bash init.sh && \
		cd .. && \
		make homestead-init FIRST_TIME_INSTALL=true; \
	fi \

homestead-init:
	cp homestead_overrides/Homestead.yaml homestead/.
	cp homestead_overrides/after.sh homestead/.
	cp -r homestead_overrides/custom_scripts homestead/.
	cd homestead && vagrant up --provision
	cd ..
	make TARGET_ENVIRONMENT=HOMESTEAD install-dependencies

homestead-box:
	vagrant box add laravel/homestead

homestead-stop:
	@cd homestead && \
	vagrant halt

homestead-start:
	@cd homestead && \
	vagrant up --provision

homestead-destroy:
	@if [ -d "homestead" ]; then \
		cd homestead && \
	 	vagrant destroy && \
	 	cd .. && \
		rm -rf homestead; \
	fi;
FIRST_TIME_INSTALL=false
setup-hostfile:
	echo '${LOCAL_SERVER_IP} ${LOCAL_SERVER_DOMAIN}' | sudo tee -a /etc/hosts
EXTRA_INSTALL_DEPENDENCIES= make key-generate && \
							make nova-install && \
							if [ "${IS_TESTING}" != "true" ] ; then \
								make config-cache && \
								if [ "${FIRST_TIME_INSTALL}" = "true" ] ; then \
									make db-reset; \
								else \
									make build; \
								fi; \
							else \
								make config-cache OVERRIDE_ENV="--env=testing" && \
								if [ "${SESSION_DRIVER}" = "database" ] || [ "${CACHE_DRIVER}" = "database" ] ; then \
									echo "IS_TESTING.. Session or Cache is using db.. migrating.. " && \
									make migrate-fresh; \
								else \
									echo "IS_TESTING.. skipping migrate "; \
								fi; \
							fi && \
							make flush

update-php-docs:
	make php-artisan ARG="ide-helper:generate"
	make php-artisan ARG='ide-helper:models -W'
	make php-artisan ARG="ide-helper:meta"

tinker:
	make php-artisan ARG="tinker"
