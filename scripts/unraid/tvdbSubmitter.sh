#!/bin/bash

docker run --rm -v /root/repos/infrastructure/scripts/unraid:/tmp/scripts \
-v /mnt/user/Media/temp/test:/tmp/episodes buildkite/puppeteer \
node /tmp/scripts/tvdbSubmitter.js email="phyzicaly@hotmail.com" username="phyzical" password=""