const puppeteer = require('puppeteer');
const fs = require('fs');

//todo make it loop folders and seasons automatically

let browser
let page
let email
let username
let password
let series
let season

const inputs = process.argv.slice(2)
for (let i = 0; i < inputs.length; i++) {
  const inputSplit = inputs[i].split('=')
  switch (inputSplit[0]) {
    case 'series':
      series = inputSplit[1]
      break;
    case 'season':
      season = inputSplit[1]
      break;
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

const baseURL = 'https://thetvdb.com/'
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

  const loginURL = baseURL + '/auth/login'
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

const getFilesToProcess = () => {
  console.log("Collating episodes")
  const files = fs.readdirSync(folder)
  const filesForProcessing = files.reduce(function (acc, file) {
    if (file.includes('.mp4')) {
      acc.push(file.replace('.mp4', ""))
    }
    return acc
  }, []).map(function (key) {

    const info = files.find(function (file) {
      return file.includes(key) && file.includes('.json')
    })

    const description = files.find(function (file) {
      return file.includes(key) && file.includes('.description')
    })

    const jpg = files.find(function (file) {
      return file.includes(key) && file.includes('-thumb.jpg')
    })

    return {
      info,
      description,
      jpg
    }
  })
  console.log("Collated episodes")
  return filesForProcessing
}

const openAddEpisodePage = async () => {
  const showSeasonURL = [baseURL, 'series', series, 'seasons', 'official', season].join('/')
  const addEpisodeSelector = '//*[contains(text(),"Add Episode")]'
  await page.goto(showSeasonURL)
  await page.waitFor(addEpisodeSelector)
  const addEpisodeButton = await page.$x(addEpisodeSelector)
  await addEpisodeButton[0].click()
}


const addEpisode = async (episode) => {
  console.log("adding episode", episode['jpg'])
  await openAddEpisodePage()
  const infoJson = JSON.parse(fs.readFileSync([folder, episode['info']].join('/')))
  const jpgFile = [folder, episode['jpg']].join('/')
  const episodeName = infoJson['fulltitle']
  let description
  if (episode['description']) {
    description = fs.readFileSync([folder, episode['description']].join('/'), 'utf8')
  } else {
    description = episodeName
  }
  const productionCode = infoJson['id']
  let airDate = infoJson['upload_date'] //'01/02/2020'
  airDate = airDate.slice(4, 6) + airDate.slice(6, 8) + airDate.slice(0, 4)
  const runtime = Math.floor((infoJson['duration'] / 60)).toString()
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
  const files = await getFilesToProcess()
  for (let i = 0; i < files.length; i++) {
    await addEpisode(files[i])
  }
  await finish();
}

run().catch(e => {
  console.log('Error: \n', e)
  finish()
})