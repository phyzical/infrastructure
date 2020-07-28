#!/bin/bash
#
# Common Silverstripey things
# # php based
#
SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(SELF_DIR)/makefile-common.mk

DEV_BUILD_SAKE_COMMAND=dev/build flush=1
POST_LOCAL_DATABASE_RESTORE_COMMAND=make ask-for-flush
POST_DATABASE_RESTORE_COMMAND=make dev-build-flush
CURRENT_TARGET_DEV_FLUSH_COMMAND=	if [ ${DEV_BUILD_FLUSH} = true ] && [ -f $(SAKE) ] && [ ! -z '${CURRENT_TARGET_PHP_LOCATION}' ]; then \
										echo "Dev Building and flushing!!!" && \
										$(CURRENT_TARGET_ENV_COMMAND) && \
										env PATH="$(CURRENT_TARGET_PHP_LOCATION):$(PATH)" $(SAKE) $(DEV_BUILD_SAKE_COMMAND) && \
										echo "Dev Build and Flush Complete" && \
										echo "Curl Flushing!!!!" && \
										curl -sIXGET "${CURRENT_TARGET_SERVER_ALIAS}" && \
										echo "Curl Flushing COMPLETE"; \
									fi
custom-sake-command-staging:
	make custom-sake-command TARGET_ENVIRONMENT=STAGING
custom-sake-command-uat:
	make custom-sake-command TARGET_ENVIRONMENT=UAT
custom-sake-command-production:
	make custom-sake-command TARGET_ENVIRONMENT=PRODUCTION

custom-sake-command:
	@make _init
	@if [ "${TARGET_ENVIRONMENT}" = "LOCAL" ] ; then \
		env PATH="$(LOCAL_PHP_LOCATION):$(PATH)" $(SAKE) $(SAKE_COMMAND); \
	else \
		$(CURRENT_TARGET_SSH) 'cd $(CURRENT_TARGET_PATH) && $(CURRENT_TARGET_SAKE_COMMAND)'; \
	fi

dev-build-flush:
	@if [ "${DEV_BUILD_FLUSH}" = "true" ] ; then \
		if [ "${TARGET_ENVIRONMENT}" = "LOCAL" ] && [ -f $(SAKE) ] && [ ! -z '${LOCAL_PHP_LOCATION}' ]; then \
			make custom-sake-command SAKE_COMMAND="$(DEV_BUILD_SAKE_COMMAND)"; \
		else \
			$(CURRENT_TARGET_SSH) 'cd $(CURRENT_TARGET_PATH) && $(CURRENT_TARGET_DEV_FLUSH_COMMAND)'; \
		fi; \
	fi

dev-build-flush-staging:
	make dev-build-flush TARGET_ENVIRONMENT="STAGING"
dev-build-flush-uat:
	make dev-build-flush TARGET_ENVIRONMENT="UAT"
dev-build-flush-production:
	make dev-build-flush TARGET_ENVIRONMENT="PRODUCTION"

ask-for-flush:
	@while [ -z "$$BUILDFLUSH" ]; do \
	read -r -p "Perform DEV-BUILD-FLUSH on Reset? [Y/n]: " BUILDFLUSH; \
	done ; \
	if [ $$BUILDFLUSH = "y" ] || [ $$BUILDFLUSH = "Y" ]; then make dev-build-flush; fi;
