import puppeteer, { Browser, Page } from "puppeteer";

import { Episode } from "../Episode.js";
import { GenericSubmitterInterface } from "../../interfaces/submitter/GenericSubmitterInterface.js";
import { ShowSubmitter } from "../../ShowSubmitter.js";

class BaseSubmitter implements GenericSubmitterInterface {
  browser: Browser;
  page: Page;
  username: string;
  email: string;
  password: string;

  constructor(username: string, password: string, email: string) {
    this.username = username;
    this.password = password;
    this.email = email;
  }

  doLogin(): Promise<void> {
    throw new Error("Method not implemented.");
  }

  openSeriesSeasonPage(series: string, season: string): Promise<void> {
    throw new Error("Method not implemented.");
  }

  addEpisode(episode: Episode, series: string, season: string): Promise<void> {
    throw new Error("Method not implemented.");
  }

  getEpisodeIdentifier(fileToRename: string): Promise<string> {
    throw new Error("Method not implemented.");
  }

  async init(): Promise<void> {
    this.browser = await puppeteer.launch({
      args: [
        // Required for Docker version of Puppeteer
        "--no-sandbox",
        "--disable-setuid-sandbox",
        // This will write shared memory files into /tmp instead of /dev/shm,
        // because Docker’s default for /dev/shm is 64MB
        "--disable-dev-shm-usage",
      ],
    });

    const browserVersion = await this.browser.version();
    console.log(`Started ${browserVersion}`);
    this.page = await this.browser.newPage();
  }

  async finish(): Promise<void> {
    const submitterName = this.constructor.name;
    const nowDateString = new Date() //
      .toJSON()
      .slice(0, 10)
      .replace(/-/g, "");
    const screenshotPath = `${ShowSubmitter.folder}/${nowDateString}-${submitterName}.png`
    console.log(`screen shot can be found at ${screenshotPath}`)
    await this.page.screenshot({
      path: screenshotPath,
      fullPage: true,
    });
    await this.browser.close();
  }
}

export { BaseSubmitter };
