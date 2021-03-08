import { BaseSubmitter } from "./BaseSubmitter.js";
import { Episode } from "../Episode.js";
import { EpisodeInformation } from "../EpisodeInformation.js";
import { setHtmlInput, submitHtmlForm } from '../../helpers/PuppeteerHelper.js';

class TvdbSubmitter extends BaseSubmitter {
  #baseURL = "https://thetvdb.com";

  async getEpisodeIdentifier(fileToRename: string): Promise<string> {
    console.log(`Looking for episode for ${fileToRename}`)

    // Remove following chars from filename and document contexts ?'/|-*: \ And lowercase all chars to increase matching
    const cleanedFilename = fileToRename
      .toLowerCase()
      .replace(/\\| |'|"|_|\/|-|\|/g, "");
    const episodeFinderSelector =
      `//tr[.//a[contains(translate(translate(translate(text(),"?'/|-*: \\",""),'"',''),` +
      `'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') ,` +
      `'${cleanedFilename}')]]/td`;
    const episodeTextElement = await this.page.$x(episodeFinderSelector);
    let episodeIdentifier = "";
    try {
      episodeIdentifier = await this.page.evaluate(
        (element: Element) => element.textContent,
        episodeTextElement[0]
      );
      console.log(`Found episode for ${fileToRename}`)
    } catch (e) {
      console.log(`Didnt find episode for ${fileToRename}`)
    }
    return episodeIdentifier;
  }

  async doLogin(): Promise<void> {
    console.log("starting login");

    const loginURL = [this.#baseURL, "auth", "login"].join("/");
    await this.page.goto(loginURL);
    // i accept is gone?
    // const iAcceptSelector = '//*[contains(text(),"I accept")]'
    // await page.waitFor(iAcceptSelector)
    // const iAcceptButton = await page.$x(iAcceptSelector)
    // await iAcceptButton[0].click()

    const loginFormSelector = 'form[action="/auth/login"]';
    await this.page.waitForSelector(loginFormSelector);
    await this.page.type('[name="email"]', this.email);
    await this.page.type('[name="password"]', this.password);
    await this.page.$eval(loginFormSelector, (form: Element) =>
      (<HTMLFormElement>form).submit()
    );

    const didLogInSelector = `//*[contains(text(),"${this.username}")]`;
    await this.page.waitForXPath(didLogInSelector);
    console.log("finishing login");
  }

  async openSeriesSeasonPage(series: string, season: string): Promise<void> {
    const seasonClean = season.split(" ")[1];
    const showSeasonURL = [
      this.#baseURL,
      "series",
      series,
      "seasons",
      "official",
      seasonClean,
    ].join("/");
    console.log(`opening ${showSeasonURL}`);
    await this.page.goto(showSeasonURL);
    let seasonSelector = `//*[contains(text(), "Season ${seasonClean}")]`;
    if (seasonClean == "0") {
      seasonSelector = `//*[contains(text(), "Specials")]`;
    }
    await this.page.waitForXPath(seasonSelector);
    console.log(`opened ${showSeasonURL}`);
  }

  private async openAddEpisodePage(series: string, season: string): Promise<void> {
    console.log("opening addEpisodePage");
    await this.openSeriesSeasonPage(series, season);
    const addEpisodeSelector = '//*[contains(text(),"Add Episode")]';
    await this.page.waitForXPath(addEpisodeSelector);
    const addEpisodeButton = await this.page.$x(addEpisodeSelector);
    await addEpisodeButton[0].click();
    console.log("opened addEpisodePage");
  }

  private async updateEpisode(
    infoJson: EpisodeInformation,
    jpgFile: string
  ): Promise<void> {
    console.log("updating episode")
    const editEpisodeFormSelector = "form.episode-edit-form";
    await this.page.waitForSelector(editEpisodeFormSelector);

    await this.page.$eval(
      "[name=productioncode]",
      setHtmlInput,
      infoJson.url()
    );
    await this.page.$eval("[name=airdate]", setHtmlInput, infoJson.airedDate());
    await this.page.$eval("[name=runtime]", setHtmlInput, infoJson.runTime());

    await this.page.waitForSelector("input[type=file]");
    if (jpgFile) {
      const elementHandle = await this.page.$("input[type=file]");
      await elementHandle.uploadFile(jpgFile);
    }
    await this.page.waitForTimeout(2000);
    await this.page.$eval(editEpisodeFormSelector, submitHtmlForm);
    const episodeAddedSuccessfully =
      '//*[contains(text(),"Episode was successfully updated!")]';
    await this.page.waitForXPath(episodeAddedSuccessfully, {
      timeout: 100000,
    });
    console.log("updated episode")
  }

  async addEpisode(
    episode: Episode,
    series: string,
    season: string
  ): Promise<void> {
    console.log("adding episode", episode.name);
    await this.openAddEpisodePage(series, season);

    const infoJson = episode.information();
    // todo this is out of date

    const addEpisodeFormSelector = "form.episode-add-form";
    await this.page.waitForSelector(addEpisodeFormSelector);
    await this.page.$eval("[name=episodename]", setHtmlInput, infoJson.title());
    await this.page.$eval(
      "[name=overview]",
      setHtmlInput,
      infoJson.description()
    );
    await this.page.$eval(addEpisodeFormSelector, submitHtmlForm);

    try {
      await this.updateEpisode(infoJson, episode.thumbnailFilePath());
    } catch (e) {
      //try again with tile
      try {
        await this.updateEpisode(infoJson, episode.thumbnailFileTilePath());
      } catch (e2) {
        // otherwise dont bother with an image
        await this.updateEpisode(infoJson, null);
      }
    }

    console.log("added episode");
  }
}

export { TvdbSubmitter };
