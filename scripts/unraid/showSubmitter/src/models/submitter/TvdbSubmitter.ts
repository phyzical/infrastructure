import { BaseSubmitter } from "./BaseSubmitter.js";
import { Episode } from "../Episode.js";
import {
  setHtmlInput,
  submitHtmlForm,
  clickHtmlElement,
} from "../../helpers/PuppeteerHelper.js";
import { log } from "../../helpers/LogHelper.js";

class TvdbSubmitter extends BaseSubmitter {
  #baseURL = "https://thetvdb.com";

  async getEpisodeIdentifier(fileToRename: string): Promise<string> {
    log(`Looking for episode for ${fileToRename}`, true);

    const filenameCleaned = fileToRename
      .toLowerCase()
      .replace(/[- '`~!@#$%^&*()_|+=?;:'",.<>\{\}\[\]\\\/]/gi, "");
    // Remove following chars from filename and document contexts ?'/|-*: \ And lowercase all chars to increase matching
    const capitalChars =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÄÇÈÉÊËÌÍÎÏÑÒÓÔÕÖŠÚÛÜÙÝŸŽ";
    const episodeFinderSelector =
      `//tr[.//a[contains(translate(translate(translate(text(),'\\\`~!@#$%^&*()-_=+[]{}|;:<>",./?, ',''), "'", ''),` +
      `'${capitalChars}', '${capitalChars.toLowerCase()}') , '${filenameCleaned}')]]/td`;
    const episodeTextElement = await this.page.$x(episodeFinderSelector);
    let episodeIdentifier = "";
    try {
      episodeIdentifier = await this.page.evaluate(
        (element: Element) => element.textContent,
        episodeTextElement[0]
      );
      log(`Found episode for ${fileToRename}`, true);
    } catch (e) {
      log(`Didnt find episode for ${fileToRename}`, true);
    }
    return episodeIdentifier;
  }

  async doLogin(): Promise<void> {
    log("starting login", true);

    const loginURL = [this.#baseURL, "auth", "login"].join("/");
    await this.page.goto(loginURL);
    const loginFormSelector = 'form[action="/auth/login"]';
    await this.page.waitForSelector(loginFormSelector);
    await this.page.type('[name="email"]', this.email);
    await this.page.type('[name="password"]', this.password);
    await this.page.$eval(loginFormSelector, (form: Element) =>
      (<HTMLFormElement>form).submit()
    );

    const didLogInSelector = `//*[contains(text(),"Logout")]`;
    await this.page.waitForXPath(didLogInSelector);
    log("finishing login", true);
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
    log(`opening ${showSeasonURL}`, true);
    await this.page.goto(showSeasonURL);
    let seasonSelector = `//*[contains(text(), "Season ${seasonClean}")]`;
    if (seasonClean == "0") {
      seasonSelector = `//*[contains(text(), "Specials")]`;
    }
    await this.page.waitForXPath(seasonSelector);
    log(`opened ${showSeasonURL}`, true);
  }

  private async openAddEpisodePage(
    series: string,
    season: string
  ): Promise<void> {
    log("opening addEpisodePage", true);
    await this.openSeriesSeasonPage(series, season);
    const addEpisodeSelector = '//*[contains(text(),"Add Episode")]';
    await this.page.waitForXPath(addEpisodeSelector, { visible: true });
    const addEpisodeButton = await this.page.$x(addEpisodeSelector);
    await addEpisodeButton[0].click();
    log("opened addEpisodePage", true);
  }

  private async addInitialEpisode(episode: Episode): Promise<boolean> {
    const infoJson = episode.information();
    log(`starting adding`, true);
    const addEpisodeFormSelector = "//h3[text()='Episodes']/ancestor::form";
    await this.page.waitForXPath(addEpisodeFormSelector);
    await this.page.$eval('[name="name[]"]', setHtmlInput, episode.title());
    await this.page.$eval(
      '[name="overview[]"]',
      setHtmlInput,
      infoJson.description()
    );
    await this.page.$eval(
      '[name="runtime[]"]',
      setHtmlInput,
      infoJson.runTime()
    );
    await this.page.$eval(
      '[name="date[]"]',
      setHtmlInput,
      infoJson.airedDate()
    );
    const addEpisodeFormElement = await this.page.$x(addEpisodeFormSelector);
    await this.page.evaluate(submitHtmlForm, addEpisodeFormElement[0]);
    log(`finished adding`, true);
    return true;
  }

  private async updateEpisode(episode: Episode): Promise<void> {
    const infoJson = episode.information();
    log("updating episode", true);
    const editEpisodeFormSelector = "form.episode-edit-form";
    await this.page.waitForSelector(editEpisodeFormSelector);

    await this.page.$eval(
      "[name=productioncode]",
      setHtmlInput,
      infoJson.url()
    );

    const saveButtonSelector = "//button[text()='Save']";
    await this.page.waitForXPath(saveButtonSelector);
    const saveButton = await this.page.$x(saveButtonSelector);
    await this.page.evaluate(clickHtmlElement, saveButton[0]);

    const episodeAddedSuccessfully = `//*[contains(text(),"${episode.title()}")]`;
    await this.page.waitForXPath(episodeAddedSuccessfully);
    log("updated episode", true);
  }

  private async uploadEpisodeThumbnail(episode: Episode): Promise<void> {
    log("Starting image upload", true);
    const thumbnailPath = episode.thumbnailFilePath();
    const addArtworkSelector = "//a[text()='Add Artwork']";
    await this.page.waitForXPath(addArtworkSelector, { visible: true });
    const addArtworkButton = await this.page.$x(addArtworkSelector);
    await this.page.evaluate(clickHtmlElement, addArtworkButton[0]);
    try {
      await this.page.waitForSelector("input[type=file]");
      const elementHandle = await this.page.$("input[type=file]");
      await elementHandle.uploadFile(thumbnailPath);
      const continueButtonSelector = "//button[text()='Continue']";
      await this.page.waitForXPath(continueButtonSelector);
      await this.page.waitForTimeout(3000);
      const continueButton = await this.page.$x(continueButtonSelector);
      await this.page.evaluate(clickHtmlElement, continueButton[0]);

      const thumbnailAddedSelector = `//*[contains(text(),"${episode.title()}")]`;
      await this.page.waitForXPath(thumbnailAddedSelector);
      log("Successfully uploaded image", true);
    } catch (e) {
      log(e);
      await this.takeScreenshot();
      log("Failed image upload");
    }
  }

  async addEpisode(
    episode: Episode,
    series: string,
    season: string
  ): Promise<void> {
    log(`Starting adding of ${episode.name}`);
    let added = false;
    try {
      await this.openAddEpisodePage(series, season);
      added = await this.addInitialEpisode(episode);
      await this.updateEpisode(episode);
    } catch (e) {
      log(e);
      // random error that occurs from time to time, only try again if its thrown from initial add
      if (!added) {
        const addEpisodeSelector =
          '//*[contains(text(),"Whoops, looks like something went wrong")]';
        await this.page.waitForXPath(addEpisodeSelector);
        await this.openAddEpisodePage(series, season);
        await this.addInitialEpisode(episode);
        await this.updateEpisode(episode);
      }
    }

    try {
      await this.uploadEpisodeThumbnail(episode);
    } catch {
      log(`sigh looks like they blocked images for ${series}`);
    }
    log(`Finished adding of ${episode.name}`);
  }
}

export { TvdbSubmitter };
