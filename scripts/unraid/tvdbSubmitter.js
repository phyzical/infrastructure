const puppeteer = require('puppeteer');
const fs = require('fs');

let browser
let page
let email
let username
let password
let renameOnly = false

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
    case 'renameOnly':
      renameOnly = inputSplit[1] == "true"
      break;
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
          const jpgTile = files.find(function (file) {
            return file.includes(key) && file.includes('.jpg')
          })

          if (!jpg) {
            jpg = jpgTile
          }

          return {
            info,
            description,
            jpg,
            jpgTile,
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
  const seasonClean = season.split(" ")[1]
  const showSeasonURL = [baseURL, 'series', series, 'seasons', 'official', seasonClean].join('/')
  await page.goto(showSeasonURL)
  let seasonSelector = `//*[contains(text(), "Season ${seasonClean}")]`
  if (seasonClean == '0') {
    seasonSelector = `//*[contains(text(), "Specials")]`
  }
  await page.waitFor(seasonSelector)
}

const openAddEpisodePage = async (series, season) => {
  await openSeriesSeasonPage(series, season)
  const addEpisodeSelector = '//*[contains(text(),"Add Episode")]'
  await page.waitFor(addEpisodeSelector)
  const addEpisodeButton = await page.$x(addEpisodeSelector)
  await addEpisodeButton[0].click()
}

const updateEpisode = async (infoJson, jpgFile) => {
  const productionCode = infoJson.id
  const runtime = Math.floor((infoJson.duration / 60)).toString()
  let airDate = infoJson.upload_date //'01/02/2020'
  airDate = `${airDate.slice(0, 4)}-${airDate.slice(4, 6)}-${airDate.slice(6, 8)}` 

  const editEpisodeFormSelector = 'form.episode-edit-form'
  await page.waitFor(editEpisodeFormSelector)
  await page.$eval('input[name=productioncode]', el => el.value = productionCode)
  await page.$eval('input[name=airdate]', el => el.value = airDate)
  await page.$eval('input[name=runtime]', el => el.value = runtime)
  await page.waitFor('input[type=file]')
  if (jpgFile) {
    const elementHandle = await page.$("input[type=file]");
    await elementHandle.uploadFile(jpgFile);
  }
  await page.waitFor(2000)
  await page.$eval(editEpisodeFormSelector, form => form.submit());
  const episodeAddedSuccessfully = '//*[contains(text(),"Episode was successfully updated!")]'
  await page.waitFor(episodeAddedSuccessfully, {
    timeout: 100000
  })
}


const addEpisode = async (episode, series, season) => {
  console.log("adding episode", episode.name)
  const seasonFolder = [folder, series, season].join('/')
  await openAddEpisodePage(series, season)
  const infoJson = JSON.parse(fs.readFileSync([seasonFolder, episode.info].join('/')))
  const jpgFile = [seasonFolder, episode.jpg].join('/')
  const jpgTile = [seasonFolder, episode.jpgTile].join('/')
  const episodeName = infoJson.fulltitle
  let description
  if (episode.description) {
    description = fs.readFileSync([seasonFolder, episode.description].join('/'), 'utf8')
  } else {
    description = episodeName
  }

  const addEpisodeFormSelector = 'form.episode-add-form'
  await page.waitFor(addEpisodeFormSelector)
  await page.$eval('input[name=episodename]', el => el.value = episodeName)
  await page.$eval('input[name=overview]', el => el.value = description.slice(0, 500))
  await page.$eval(addEpisodeFormSelector, form => form.submit());

  try {
    await updateEpisode(infoJson, jpgFile)
  } catch (e) {
    //try again with tile
    try {
      await updateEpisode(infoJson, jpgTile)
    } catch (e2) {
      // otherwise dont bother with an image
      await updateEpisode(infoJson)
    }
  }

  console.log("added episode")
}

const renameEpisode = async (fileToRename, episodeTextElement, series, season) => {
  console.log(`starting renaming ${fileToRename}`)
  const seasonFolder = [folder, series, season].join('/')
  const files = fs.readdirSync(seasonFolder)
  try {
    const episodeText = await page.evaluate(element => element.textContent, episodeTextElement[0]);
    files.forEach(function (file) {
      if (file.includes(`$(fileToRename}.`) || file.includes(`$(fileToRename}-`)) {
        const filePath = [seasonFolder, file].join('/')
        if (file.includes(".description") || file.includes(".json")) {
          fs.unlinkSync(filePath)
        } else {
          const newName = `${series.replace(/-/g,'.')}.${episodeText}${file.substring(file.indexOf("."))}`
          fs.renameSync(filePath, [seasonFolder, newName].join('/'))
        }
      }
    })
  } catch (e) {
    console.log("renaming failed")
    files.forEach(function (file) {
      if (file.includes(fileToRename)) {
        const errorDir = [seasonFolder, 'errored'].join('/')
        if (!fs.existsSync(errorDir)) {
          fs.mkdirSync(errorDir);
        }
        fs.renameSync([seasonFolder, file].join('/'), [errorDir, file].join('/'))
      }
    })
  }
  console.log("finished renaming")
}

const finish = async () => {
  // await page.screenshot({
  //   path: '/tmp/scripts/screenshot.png',
  //   fullPage: true
  // });
  await browser.close();
}

const run = async () => {
  await init();
  await doLogin();
  const shows = await getFilesToProcess()
  for (const [series, seasons] of Object.entries(shows)) {
    for (const [season, episodes] of Object.entries(seasons)) {
      console.log(`Starting ${series} - season ${season}`)
      await openSeriesSeasonPage(series, season)
      for (const episode of episodes) {
        const fileToRename = episode.name.substring(episode.name.indexOf(".") + 1)
        const episodeFinderSelector = `//tr[.//a[contains(text(),"${fileToRename}") or contains(translate(translate(text(),"?'/|-*: ",""),'"',''),'${fileToRename.replace(/ |'|"|_|\/|-|\|/g,"")}')]]/td`
        let episodeTextElement = await page.$x(episodeFinderSelector)
        if (!renameOnly && episodeTextElement.length == 0) {
          await addEpisode(episode, series, season)
          await openSeriesSeasonPage(series, season)
          episodeTextElement = await page.$x(episodeFinderSelector)
        }
        await renameEpisode(fileToRename, episodeTextElement, series, season);
      }
    }
  }
  await finish();
}

run().catch(e => {
  console.log('Error: \n', e)
  finish()
})
