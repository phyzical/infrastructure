const puppeteer = require('puppeteer');
const fs = require('fs');

let browser
let page
let email
let username
let password

const inputs = process.argv.slice(2)
for (let i = 0; i < inputs.length; i++) {
  const inputSplit = inputs[i].split('=')
  switch (inputSplit[0]) {
    case 'email':
      email = inputSplit[1]
      break;
    case 'password':
      password = inputSplit[1]
      break;
    case 'username':
      username = inputSplit[1]
      break
  }
}

const baseURL = 'https://thetvdb.com'
const folder = "/tmp/episodes"

const init = async () => {
  browser = await puppeteer.launch({
    args: [
      // Required for Docker version of Puppeteer
      '--no-sandbox',
      '--disable-setuid-sandbox',
      // This will write shared memory files into /tmp instead of /dev/shm,
      // because Docker’s default for /dev/shm is 64MB
      '--disable-dev-shm-usage'
    ]
  })

  const browserVersion = await browser.version()
  console.log(`Started ${browserVersion}`)
  page = await browser.newPage();
}

const doLogin = async () => {
  console.log("starting login")

  const loginURL = [baseURL, 'auth', 'login'].join('/')
  const iAcceptSelector = '//*[contains(text(),"I accept")]'
  await page.goto(loginURL)
  await page.waitFor(iAcceptSelector)
  const iAcceptButton = await page.$x(iAcceptSelector)
  await iAcceptButton[0].click()

  const loginFormSelector = 'form[action="/auth/login"]'
  await page.waitFor(loginFormSelector)
  await page.type('[name="email"]', email)
  await page.type('[name="password"]', password)
  await page.$eval(loginFormSelector, form => form.submit());

  const didLogInSelector = `//*[contains(text(),"${username}")]`
  await page.waitFor(didLogInSelector)
  console.log("finishing login")
}

const getDirectories = source =>
  fs.readdirSync(source, {
    withFileTypes: true
  })
  .filter(dirent => dirent.isDirectory())
  .map(dirent => dirent.name)

const getFilesToProcess = () => {
  console.log("Collating episodes")

  const fileAccumulator = (acc, file) => {
    if (!isNaN(file[0]) && file.includes('.mp4')) {
      acc.push(file.replace('.mp4', ""))
    }
    return acc
  }
  const seriesAccumulator = (seriesAcc, series) => {
    seriesAcc[series] = getDirectories([folder, series].join('/')).reduce((seasonAcc, season) => {
      if (season.includes('season') || season.includes('Season')) {
        const files = fs.readdirSync([folder, series, season].join('/'))
        seasonAcc[season] = files.reduce(fileAccumulator, []).map((key) => {
          const info = files.find(function (file) {
            return file.includes(key) && file.includes('.json')
          })

          const description = files.find(function (file) {
            return file.includes(key) && file.includes('.description')
          })

          let jpg = files.find(function (file) {
            return file.includes(key) && file.includes('-thumb.jpg')
          })

          // look for non thumb as backup
          if (!jpg) {
            jpg = files.find(function (file) {
              return file.includes(key) && file.includes('.jpg')
            })
          }

          return {
            info,
            description,
            jpg,
            name: key
          }
        })
      }
      return seasonAcc
    }, {})
    return seriesAcc
  }

  const filesForProcessing = getDirectories(folder).reduce(seriesAccumulator, {})
  console.log("Collated episodes")
  return filesForProcessing
}

const openSeriesSeasonPage = async (series, season) => {
  const showSeasonURL = [baseURL, 'series', series, 'seasons', 'official', season].join('/')
  await page.goto(showSeasonURL)
  const seasonSelector = `//*[contains(text(), "Season ${season}")]`
  await page.waitFor(seasonSelector)
}

const openAddEpisodePage = async (series, season) => {
  await openSeriesSeasonPage(series, season)
  const addEpisodeSelector = '//*[contains(text(),"Add Episode")]'
  await page.waitFor(addEpisodeSelector)
  const addEpisodeButton = await page.$x(addEpisodeSelector)
  await addEpisodeButton[0].click()
}


const addEpisode = async (episode, series, season) => {
  console.log("adding episode", episode.jpg)
  const seasonFolder = [folder, series, season].join('/')
  await openAddEpisodePage(series, season)
  const infoJson = JSON.parse(fs.readFileSync([seasonFolder, episode.info].join('/')))
  const jpgFile = [seasonFolder, episode.jpg].join('/')
  const episodeName = infoJson.fulltitle
  let description
  if (episode.description) {
    description = fs.readFileSync([seasonFolder, episode.description].join('/'), 'utf8')
  } else {
    description = episodeName
  }
  const productionCode = infoJson.id
  let airDate = infoJson.upload_date //'01/02/2020'
  airDate = airDate.slice(4, 6) + airDate.slice(6, 8) + airDate.slice(0, 4)
  const runtime = Math.floor((infoJson.duration / 60)).toString()
  const addEpisodeFormSelector = 'form.episode-add-form'

  await page.waitFor(addEpisodeFormSelector)
  await page.type('[name="episodename"]', episodeName)
  await page.type('[name="overview"]', description)
  await page.waitFor(2000)
  await page.$eval(addEpisodeFormSelector, form => form.submit());

  const editEpisodeFormSelector = 'form.episode-edit-form'
  await page.waitFor(editEpisodeFormSelector)
  await page.type('[name="productioncode"]', productionCode)
  await page.type('[name="airdate"]', airDate)
  await page.type('[name="runtime"]', runtime)
  await page.waitFor('input[type=file]')
  const elementHandle = await page.$("input[type=file]");
  await elementHandle.uploadFile(jpgFile);
  await page.waitFor(2000)
  await page.$eval(editEpisodeFormSelector, form => form.submit());

  const episodeAddedSuccessfully = '//*[contains(text(),"Episode was successfully updated!")]'
  await page.waitFor(episodeAddedSuccessfully)
  console.log("added episode")
}

const renameEpisode = async (fileToRename, series, season) => {
  console.log(`starting renaming ${fileToRename}`)
  const seasonFolder = [folder, series, season].join('/')
  const episodeFinderSelector = `//tr[.//a[contains(text(),"${fileToRename}")]]/td`
  const episodeTextElement = await page.$x(episodeFinderSelector)
  const episodeText = await page.evaluate(element => element.textContent, episodeTextElement[0]);
  const files = fs.readdirSync(seasonFolder)
  files.forEach(function (file) {
    if (file.includes(fileToRename)) {
      const newName = `${series.replace('-','.')}.${episodeText}${file.substring(file.indexOf("."))}`
      fs.renameSync([seasonFolder, file].join('/'), [seasonFolder, newName].join('/'))
    }
  })
  console.log("finished renaming")
}

const finish = async () => {
  await page.screenshot({
    path: '/tmp/scripts/screenshot.png',
    fullPage: true
  });
  await browser.close();
}

const run = async () => {
  await init();
  await doLogin();
  const shows = await getFilesToProcess()
  for (const [series, seasons] of Object.entries(shows)) {
    for (const [season, episodes] of Object.entries(seasons)) {
      const seasonClean = season.split(" ")[1]
      await openSeriesSeasonPage(series, seasonClean)
      for (const episode of episodes) {
        const fileToRename = episode.name.substring(episode.name.indexOf(".") + 1)
        const episodeFinderSelector = `//tr[.//a[contains(text(),"${fileToRename}")]]/td`
        const episodeTextElement = await page.$x(episodeFinderSelector)
        if (episodeTextElement.length == 0) {
          await addEpisode(episode, series, season)
        }
        await renameEpisode(fileToRename, series, season);
      }
    }
  }
  await finish();
}

//todo update any shows with - for spaces in youtubedownloader

run().catch(e => {
  console.log('Error: \n', e)
  finish()
})