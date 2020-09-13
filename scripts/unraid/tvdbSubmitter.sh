#!/bin/bash

docker run --rm -v /mnt/user//infrastructure/scripts/unraid:/tmp/scripts \
-v "/mnt/user/Media/temp/VinWiki/Season 4":/tmp/episodes buildkite/puppeteer \
node /tmp/scripts/tvdbSubmitter.js series="vinwiki" season="4" \
email="phyzicaly@hotmail.com" username="phyzical" password=""