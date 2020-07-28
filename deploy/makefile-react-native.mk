#!/bin/bash
#
# Common Makefile to handle deployments of headless vue apps
#
SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(SELF_DIR)/makefile-static.mk

ENV_FILES=.env .env.staging .env.uat .env.production .env.test
IOS_SIMULATOR_NAME=iPhone 7
ANDROID_SIMULATOR_NAME=Pixel_2_API_28
XCODE_EXECUTABLE=xcodebuild
APP_STORE_USERNAME=
APP_STORE_PASSWORD=
RUN_STYLELINT=false
FULL_TEST_COMMAND=	npm test

first-time-install:
	@if [ ${IS_OSX} = true ]; then \
		${OS_PACKAGE_MANAGER} install watchman && \
		sudo gem install cocoapods -v 1.7.5 && \
		pod init; \
	fi;
	if [ ${IS_LINUX} = true ]; then \
		sudo ${OS_PACKAGE_MANAGER} install -y autoconf automake build-essential python-dev libtool libssl-dev pkg-config && \
		cd ~/Apps && \
		git clone https://github.com/facebook/watchman.git -b v4.9.0 --depth 1; \
		cd watchman/ && \
		./autogen.sh && \
		./configure --enable-lenient && \
		make && \
		sudo make install; \
	fi;
	npm install -g react-native-cli; \
	make reset-app-plugins

reset-app-plugins:
	rm -rf ${TMPDIR}]/metro-*;
	rm -rf ${TMPDIR}/haste-*;
	rm -rf ~/Library/Developer/Xcode/DerivedData;
	rm -fr ~/rncache;
	watchman watch-del-all;
	npm cache clean --force;
	npm cache verify;
	rm -rf ios/build;
	rm -rf node_modules/;
	npm install;
	rm -rf node_modules/react-native-push-notification/.git;
	if [ ${IS_OSX} = true ]; then \
		cd ios && rm -rf Pods podfile.lock && pod deintegrate && pod install --repo-update; \
	fi;
	##npx jetify
	#react-native link

coverages:
	npm run coverage
APP_NAME=${PROJECT_NAME}_$(GIT_TAG)_${BUILD_COUNTER}

## ios
run-ios:
	react-native run-ios --simulator="$(IOS_SIMULATOR_NAME)"
open-ios-project:
	open /Applications/Xcode.app ios/${PROJECT_NAME}.xcworkspace
#configure in project. Tools --> Create command line launcher.
EXPORT_PLIST=exportOptions.plist
build-ios-release:
	make create-app-files
	cd ios/ && \
	/usr/libexec/Plistbuddy -c "Set CFBundleVersion ${BUILD_COUNTER}" ${PROJECT_NAME}/Info.plist && \
	/usr/libexec/Plistbuddy -c "Set CFBundleShortVersionString ${GIT_TAG_NUMBER}" ${PROJECT_NAME}/Info.plist && \
	${XCODE_EXECUTABLE} -workspace ${PROJECT_NAME}.xcworkspace -allowProvisioningUpdates -scheme ${PROJECT_NAME} -sdk iphoneos \
		-configuration Release clean archive -archivePath build/${PROJECT_NAME}.xcarchive && \
	${XCODE_EXECUTABLE} -exportArchive -allowProvisioningUpdates -archivePath build/${PROJECT_NAME}.xcarchive -exportOptionsPlist \
		${PROJECT_NAME}/${EXPORT_PLIST} -exportPath build
upload-ios-to-store:
	xcrun altool \
		--upload-app -f "ios/build/${PROJECT_NAME}.ipa" -u ${APP_STORE_USERNAME} -p ${APP_STORE_PASSWORD}
upload-ios-to-server:
	@echo "Uploading ios/build/${PROJECT_NAME}.ipa to ${CURRENT_TARGET_SERVER}:$(CURRENT_TARGET_PATH)assets/builds/ios/${APP_NAME}.ipa"
	rsync -av -e ssh ios/build/${PROJECT_NAME}.ipa $(CURRENT_TARGET_USER)@$(CURRENT_TARGET_SERVER):$(CURRENT_TARGET_PATH)assets/builds/ios/${APP_NAME}.ipa

build-ios-release-staging:
	make build-ios-release ENV_TO_USE=.env.staging EXPORT_PLIST=exportAdhocOptions.plist
	make upload-ios-to-server TARGET_ENVIRONMENT=STAGING ENV_TO_USE=.env.staging
build-ios-release-uat:
	make build-ios-release ENV_TO_USE=.env.uat EXPORT_PLIST=exportAdhocOptions.plist
	make upload-ios-to-server TARGET_ENVIRONMENT=UAT ENV_TO_USE=.env.uat
build-ios-release-production:
	make build-ios-release ENV_TO_USE=.env.production
	#make upload-ios-to-server TARGET_ENVIRONMENT=PRODUCTION ENV_TO_USE=.env.production
	make upload-ios-to-store ENV_TO_USE=.env.production


## android
open-android-project:
	studio ./android
run-android:
	make run-android-simulator
	cd android && ./gradlew clean
	react-native run-android
build-android-debug:
	cd android && ./gradlew clean && ./gradlew assembleDebug
build-android-release:
	make create-app-files && \
	cd android && ./gradlew clean && ./gradlew assembleRelease
build-android-to-store:
	make create-app-files && \
	cd android && ./gradlew clean && ./gradlew publishApk
upload-android-to-server:
	@echo "Uploading android/app/build/outputs/apk/release/app-release.apk to ${CURRENT_TARGET_SERVER}:$(CURRENT_TARGET_PATH)assets/builds/android/${APP_NAME}.apk"
	rsync -av -e ssh android/app/build/outputs/apk/release/app-release.apk $(CURRENT_TARGET_USER)@$(CURRENT_TARGET_SERVER):$(CURRENT_TARGET_PATH)assets/builds/android/${APP_NAME}.apk
build-android-release-staging:
	make build-android-release ENV_TO_USE=.env.staging
	make upload-android-to-server TARGET_ENVIRONMENT=STAGING ENV_TO_USE=.env.staging
build-android-release-uat:
	make build-android-release ENV_TO_USE=.env.uat
	make upload-android-to-server TARGET_ENVIRONMENT=UAT ENV_TO_USE=.env.uat
build-android-release-production:
	make build-android-to-store ENV_TO_USE=.env.production
	make upload-android-to-server TARGET_ENVIRONMENT=PRODUCTION ENV_TO_USE=.env.production

create-app-files:
	make create-version-file
	make create-sentry-files
	make create-env-file

create-env-file:
	mv .env .env.old.$(TIMESTAMP)
	echo "SENTRY_PROJECT_ID=${SENTRY_PROJECT_ID}" > .env
	echo "SENTRY_DSN=${SENTRY_DSN_PHP}" >> .env
	echo "SERVER_DOMAIN=${SERVER_DOMAIN}" >> .env
	echo "ENCRYPTION_SECRET=${ENCRYPTION_SECRET}" >> .env

create-version-file:
	echo "VERSION_BUILD=${BUILD_COUNTER}" > android/app/version.properties
	printf "GIT_TAG=${GIT_TAG}" >> android/app/version.properties

create-sentry-files:
	echo "defaults.url=https://sentry.strangeanimals.com.au/" > android/sentry.properties
	echo "defaults.org=strangeanimals" >> android/sentry.properties
	echo "defaults.project=$(SENTRY_PROJECT_NAME)" >> android/sentry.properties
	echo "http.verify_ssl=true" >> android/sentry.properties
	echo "auth.token=$(SENTRY_AUTH_TOKEN)" >> android/sentry.properties
	echo "cli.executable=node_modules/@sentry/cli/bin/sentry-cli" >> android/sentry.properties
	cp android/sentry.properties ios/sentry.properties

upload-coverage-to-staging:
	rsync --recursive -e ssh coverage $(STAGING_USER)@$(STAGING_SERVER):$(STAGING_PATH)/assets/coverage/js

##install
##brew update && brew cask install react-native-debugger
run-debugger:
	open "rndebugger://set-debugger-loc?host=localhost&port=8081"

run-ios-simulator:
	open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app

run-android-simulator:
	emulator -avd $(ANDROID_SIMULATOR_NAME) -netdelay none -netspeed full &>/dev/null &

