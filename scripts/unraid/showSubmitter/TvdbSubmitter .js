import GenericSubmitter from './GenericSubmitter'
const fs = require('fs');

class TvdbSubmitter extends GenericSubmitter {
  #baseURL = 'https://thetvdb.com'

  async getEpisodeIdentifier (fileToRename) {

    // Remove following chars from filename and document contexts ?'/|-*: \ And lowercase all chars to increase matching
    const episodeFinderSelector = `//tr[.//a[contains(translate(translate(translate(text(),"?'/|-*: \\",""),'"',''),` +
                                  `'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') ,` +
                                  `'${fileToRename.toLowerCase().replace(/\\| |'|"|_|\/|-|\|/g,"")}')]]/td`
    const episodeTextElement = await this.page.$x(episodeFinderSelector)
    let episodeIdentifier = ""
    try {
      episodeIdentifier = await page.evaluate(element => element.textContent, episodeTextElement[0])
    } catch(e) {
      console.log(e)
    }
    return episodeIdentifier
  } 

  async doLogin () {
    console.log("starting login")
    
    const loginURL = [this.#baseURL, 'auth', 'login'].join('/')
    await this.page.goto(loginURL)
    // i accept is gone?
    // const iAcceptSelector = '//*[contains(text(),"I accept")]'
    // await page.waitFor(iAcceptSelector)
    // const iAcceptButton = await page.$x(iAcceptSelector)
    // await iAcceptButton[0].click()
  
    const loginFormSelector = 'form[action="/auth/login"]'
    await this.page.waitFor(loginFormSelector)
    await this.page.type('[name="email"]', this.email)
    await this.page.type('[name="password"]', this.password)
    await this.page.$eval(loginFormSelector, form => form.submit());
  
    const didLogInSelector = `//*[contains(text(),"${this.username}")]`
    await this.page.waitFor(didLogInSelector)
    console.log("finishing login")
  }

  async openSeriesSeasonPage (series, season) {
    const seasonClean = season.split(" ")[1]
    const showSeasonURL = [this.#baseURL, 'series', series, 'seasons', 'official', seasonClean].join('/')
    await this.page.goto(showSeasonURL)
    let seasonSelector = `//*[contains(text(), "Season ${seasonClean}")]`
    if (seasonClean == '0') {
      seasonSelector = `//*[contains(text(), "Specials")]`
    }
    await this.page.waitFor(seasonSelector)
  }

  async openAddEpisodePage (series, season) {
    await this.openSeriesSeasonPage(series, season)
    const addEpisodeSelector = '//*[contains(text(),"Add Episode")]'
    await this.page.waitFor(addEpisodeSelector)
    const addEpisodeButton = await this.page.$x(addEpisodeSelector)
    await addEpisodeButton[0].click()
  }

  async _updateEpisode (infoJson, jpgFile) {
    const productionCode = infoJson.id
    let runtime = Math.floor((infoJson.duration / 60))
    runtime = runtime > 1 ? runtime.toString() : "1"
    let airDate = infoJson.upload_date //'01/02/2020'
    airDate = `${airDate.slice(0, 4)}-${airDate.slice(4, 6)}-${airDate.slice(6, 8)}`
  
    const editEpisodeFormSelector = 'form.episode-edit-form'
    await this.page.waitFor(editEpisodeFormSelector)
    await this.page.$eval('[name=productioncode]', (el, v) => el.value = v, productionCode)
    await this.page.$eval('[name=airdate]', (el, v) => el.value = v, airDate)
    await this.page.$eval('[name=runtime]', (el, v) => el.value = v, runtime)
    await this.page.waitFor('input[type=file]')
    if (jpgFile) {
      const elementHandle = await this.page.$("input[type=file]");
      await elementHandle.uploadFile(jpgFile);
    }
    await this.page.waitFor(2000)
    await this.page.$eval(editEpisodeFormSelector, form => form.submit());
    const episodeAddedSuccessfully = '//*[contains(text(),"Episode was successfully updated!")]'
    await this.page.waitFor(episodeAddedSuccessfully, {
      timeout: 100000
    })
  }

  async addEpisode (episode, series, season) {
    console.log("adding episode", episode.name)
    await this._openAddEpisodePage(series, season)
    const infoJson = JSON.parse(fs.readFileSync(episode.info))
    const episodeName = infoJson.fulltitle
    let description = episodeName
  
    // if (episode.description) {
    //   description = fs.readFileSync([seasonFolder, episode.description].join('/'), 'utf8')
    // description.slice(0, 500)
    // }
  
    const addEpisodeFormSelector = 'form.episode-add-form'
    await this.page.waitFor(addEpisodeFormSelector)
    await this.page.$eval('[name=episodename]', (el, v) => el.value = v, episodeName)
    await this.page.$eval('[name=overview]', (el, v) => el.value = v, description)
    await this.page.$eval(addEpisodeFormSelector, form => form.submit());
  
    try {
      await this._updateEpisode(infoJson, episode.jpg)
    } catch (e) {
      //try again with tile
      try {
        await this._updateEpisode(infoJson, episode.jpgTile)
      } catch (e2) {
        // otherwise dont bother with an image
        await this._updateEpisode(infoJson)
      }
    }
  
    console.log("added episode")
  }
}

export default TvdbSubmitter
