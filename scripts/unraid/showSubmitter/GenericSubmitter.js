const puppeteer = require('puppeteer');
const { exception } = require('console');

class GenericSubmitter {
  browser
  page

  username
  email
  password

  constructor (username, password, email) {
    this.username = username
    this.password = password
    this.email = email
  }

  async init () {
    this.browser = await puppeteer.launch({
      args: [
        // Required for Docker version of Puppeteer
        '--no-sandbox',
        '--disable-setuid-sandbox',
        // This will write shared memory files into /tmp instead of /dev/shm,
        // because Docker’s default for /dev/shm is 64MB
        '--disable-dev-shm-usage'
      ]
    })
  
    const browserVersion = await this.browser.version()
    console.log(`Started ${browserVersion}`)
    this.page = await this.browser.newPage();
  }

  async finish () {
    const submitterName = this.constructor.name
    const nowDateString = new Date().toJSON().slice(0,10).replace(/-/g,'');
    await this.page.screenshot({
      path: `/tmp/scripts/${nowDateString}-${submitterName}.png`,
      fullPage: true
    });
    await this.browser.close();
  }

  async doLogin () {
    throw new exception("Please Implement doLogin")
  }

  async openSeriesSeasonPage () {
    throw new exception("Please Implement openSeriesSeasonPage")
  }

  async addEpisode () {
    throw new exception("Please Implement addEpisode")
  }

  async getEpisodeIdentifier() {
    throw new exception("Please Implement getEpisodeElementNode")
  } 
}

export default GenericSubmitter
