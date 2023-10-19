import { BaseSubmitter } from "./BaseSubmitter.js";
import { Episode } from "../Episode.js";
import {
  setHtmlInput,
  submitHtmlForm,
  clickHtmlElement,
  delay,
} from "../../helpers/PuppeteerHelper.js";
import { log } from "../../helpers/LogHelper.js";

class TvdbSubmitter extends BaseSubmitter {
  #baseURL = "https://thetvdb.com";

  getEpisodeXpath(episodeTitle: string): string {
    const filenameCleaned = episodeTitle
      .toLowerCase()
      .replace(/[- '`~!@#$%^&*()_|+=?;:'",.<>\{\}\[\]\\\/]/gi, "");
    // Remove following chars from filename and document contexts ?'/|-*: \ And lowercase all chars to increase matching
    const capitalChars =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÄÇÈÉÊËÌÍÎÏÑÒÓÔÕÖŠÚÛÜÙÝŸŽ";
    return (
      `//tr[.//a[contains(translate(translate(translate(text(),'\\\`~!@#$%^&*()-_=+[]{}|;:<>",./?, ',''), "'", ''),` +
      `'${capitalChars}', '${capitalChars.toLowerCase()}') , '${filenameCleaned}')]]/td`
    );
  }

  async getEpisodeIdentifier(episodeTitle: string): Promise<string> {
    log(`Looking for episode for ${episodeTitle}`, true);
    const episodeTextElement = await this.page.$x(
      this.getEpisodeXpath(episodeTitle)
    );
    let episodeIdentifier = "";
    try {
      episodeIdentifier = await this.page.evaluate(
        (element: Element) => element.textContent,
        episodeTextElement[0]
      );
      log(`Found episode for ${episodeTitle}`, true);
    } catch (e) {
      log(`Didnt find episode for ${episodeTitle}`, true);
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

  async addSeriesSeason(series: string, season: string): Promise<void> {
    const seasonClean = season.split(" ")[1];
    await this.openSeriesPage(series);

    const openSeasonsButton = await this.page.$x(`//a[text()="Seasons"]`);
    await openSeasonsButton[0].click();

    const addSeasonButton = await this.page.$x(`//button[@title="Add Season"]`);
    await addSeasonButton[0].click();

    await this.page.$eval('[name="season_number"]', setHtmlInput, seasonClean);

    const saveSeasonsButton = await this.page.$x(
      `//button[text()="Add Season"]`
    );
    await saveSeasonsButton[0].click();

    await this.page.waitForXPath(`//*[contains(text(), "Season ${season}")]`);

    log(`Added ${series} - ${seasonClean}`, true);
  }

  async openSeriesPage(series) {
    const showSeriesURL = [this.#baseURL, "series", series].join("/");
    log(`opening ${showSeriesURL}`, true);
    await this.page.goto(showSeriesURL);
    let seriesSelector = `//*[contains(text(), "${series}")]`;
    await this.page.waitForXPath(seriesSelector);
    log(`opened ${showSeriesURL}`, true);
  }

  private async openAddEpisodePage(
    series: string,
    season: string
  ): Promise<void> {
    log("opening addEpisodePage", true);
    try {
      await this.openSeriesSeasonPage(series, season);
    } catch {
      await this.addSeriesSeason(series, season);
      await this.openSeriesSeasonPage(series, season);
    }
    const addEpisodeSelector = '//*[contains(text(),"Add Episode")]';
    await this.page.waitForXPath(addEpisodeSelector, { visible: true });
    const addEpisodeButton = await this.page.$x(addEpisodeSelector);
    await addEpisodeButton[0].click();
    log("opened addEpisodePage", true);
  }

  private async openEditEpisodePage(
    series: string,
    season: string,
    episode: Episode
  ): Promise<void> {
    const episodeTitle = episode.title();
    log(`opening editEpisodePage ${episodeTitle}`, true);
    await delay(500);
    await this.openSeriesSeasonPage(series, season);
    const episodeLink = await this.page.$x(
      this.getEpisodeXpath(episode.title())
    );
    await episodeLink[0].click();
    const editEpisodeButtonSelector = '//*[contains(text(),"Edit Episode")]';
    const editEpisodeButton = await this.page.$x(editEpisodeButtonSelector);
    await editEpisodeButton[0].click();
    log(`opened editEpisodePage ${episodeTitle}`, true);
  }

  private async addInitialEpisode(episode: Episode): Promise<void> {
    const infoJson = episode.information();
    log(`starting adding`, true);
    const addEpisodeFormSelector = "//h3[text()='Episodes']/ancestor::form";
    await this.page.waitForXPath(addEpisodeFormSelector);
    await delay(500);
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
    await delay(500);
    const addEpisodeFormElement = await this.page.$x(addEpisodeFormSelector);
    await this.page.evaluate(submitHtmlForm, addEpisodeFormElement[0]);
    log(`finished adding`, true);
  }

  private async updateEpisode(episode: Episode): Promise<void> {
    const infoJson = episode.information();
    log("updating episode", true);
    const editEpisodeFormSelector = "form.episode-edit-form";
    await this.page.waitForSelector(editEpisodeFormSelector);
    await delay(500);
    await this.page.$eval(
      "[name=productioncode]",
      setHtmlInput,
      infoJson.url()
    );
    await delay(500);
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
    await this.page.waitForXPath(addArtworkSelector);
    const addArtworkButton = await this.page.$x(addArtworkSelector);
    await this.page.evaluate(clickHtmlElement, addArtworkButton[0]);
    try {
      const fileSelector = "input[name='file']";
      await this.page.waitForSelector(fileSelector);
      const elementHandle = await this.page.$(fileSelector);
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
      // await this.takeScreenshot();
      log("Failed image upload");
    }
  }

  async addEpisode(
    episode: Episode,
    series: string,
    season: string
  ): Promise<void> {
    log(`Starting adding of ${episode.name}`);
    await this.openAddEpisodePage(series, season);
    await this.addInitialEpisode(episode);
    try {
      const addEpisodeSelector =
        '//*[contains(text(),"Whoops, looks like something went wrong")]';
      await this.page.waitForXPath(addEpisodeSelector);
      try {
        await this.openEditEpisodePage(series, season, episode);
      } catch (e) {
        log(e);
      }
    } catch (_e) {}
    await this.updateEpisode(episode);

    try {
      await this.uploadEpisodeThumbnail(episode);
    } catch (e) {
      log(`sigh looks like they blocked images for ${series} (${e})`);
    }
    log(`Finished adding of ${episode.name}`);
  }
}

export { TvdbSubmitter };
