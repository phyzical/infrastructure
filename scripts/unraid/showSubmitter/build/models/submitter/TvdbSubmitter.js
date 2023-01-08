var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __classPrivateFieldGet = (this && this.__classPrivateFieldGet) || function (receiver, privateMap) {
    if (!privateMap.has(receiver)) {
        throw new TypeError("attempted to get private field on non-instance");
    }
    return privateMap.get(receiver);
};
var _baseURL;
import { BaseSubmitter } from "./BaseSubmitter.js";
import { setHtmlInput, submitHtmlForm, clickHtmlElement, delay, } from "../../helpers/PuppeteerHelper.js";
import { log } from "../../helpers/LogHelper.js";
class TvdbSubmitter extends BaseSubmitter {
    constructor() {
        super(...arguments);
        _baseURL.set(this, "https://thetvdb.com");
    }
    getEpisodeXpath(episodeTitle) {
        const filenameCleaned = episodeTitle
            .toLowerCase()
            .replace(/[- '`~!@#$%^&*()_|+=?;:'",.<>\{\}\[\]\\\/]/gi, "");
        // Remove following chars from filename and document contexts ?'/|-*: \ And lowercase all chars to increase matching
        const capitalChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÄÇÈÉÊËÌÍÎÏÑÒÓÔÕÖŠÚÛÜÙÝŸŽ";
        return (`//tr[.//a[contains(translate(translate(translate(text(),'\\\`~!@#$%^&*()-_=+[]{}|;:<>",./?, ',''), "'", ''),` +
            `'${capitalChars}', '${capitalChars.toLowerCase()}') , '${filenameCleaned}')]]/td`);
    }
    getEpisodeIdentifier(episodeTitle) {
        return __awaiter(this, void 0, void 0, function* () {
            log(`Looking for episode for ${episodeTitle}`, true);
            const episodeTextElement = yield this.page.$x(this.getEpisodeXpath(episodeTitle));
            let episodeIdentifier = "";
            try {
                episodeIdentifier = yield this.page.evaluate((element) => element.textContent, episodeTextElement[0]);
                log(`Found episode for ${episodeTitle}`, true);
            }
            catch (e) {
                log(`Didnt find episode for ${episodeTitle}`, true);
            }
            return episodeIdentifier;
        });
    }
    doLogin() {
        return __awaiter(this, void 0, void 0, function* () {
            log("starting login", true);
            const loginURL = [__classPrivateFieldGet(this, _baseURL), "auth", "login"].join("/");
            yield this.page.goto(loginURL);
            const loginFormSelector = 'form[action="/auth/login"]';
            yield this.page.waitForSelector(loginFormSelector);
            yield this.page.type('[name="email"]', this.email);
            yield this.page.type('[name="password"]', this.password);
            yield this.page.$eval(loginFormSelector, (form) => form.submit());
            const didLogInSelector = `//*[contains(text(),"Logout")]`;
            yield this.page.waitForXPath(didLogInSelector);
            log("finishing login", true);
        });
    }
    openSeriesSeasonPage(series, season) {
        return __awaiter(this, void 0, void 0, function* () {
            const seasonClean = season.split(" ")[1];
            const showSeasonURL = [
                __classPrivateFieldGet(this, _baseURL),
                "series",
                series,
                "seasons",
                "official",
                seasonClean,
            ].join("/");
            log(`opening ${showSeasonURL}`, true);
            yield this.page.goto(showSeasonURL);
            let seasonSelector = `//*[contains(text(), "Season ${seasonClean}")]`;
            if (seasonClean == "0") {
                seasonSelector = `//*[contains(text(), "Specials")]`;
            }
            yield this.page.waitForXPath(seasonSelector);
            log(`opened ${showSeasonURL}`, true);
        });
    }
    addSeriesSeason(series, season) {
        return __awaiter(this, void 0, void 0, function* () {
            const seasonClean = season.split(" ")[1];
            yield this.openSeriesPage(series);
            const openSeasonsButton = yield this.page.$x(`//a[text()="Seasons"]`);
            yield openSeasonsButton[0].click();
            const addSeasonButton = yield this.page.$x(`//button[@title="Add Season"]`);
            yield addSeasonButton[0].click();
            yield this.page.$eval('[name="season_number"]', setHtmlInput, seasonClean);
            const saveSeasonsButton = yield this.page.$x(`//button[text()="Add Season"]`);
            yield saveSeasonsButton[0].click();
            yield this.page.waitForXPath(`//*[contains(text(), "Season ${season}")]`);
            log(`Added ${series} - ${seasonClean}`, true);
        });
    }
    openSeriesPage(series) {
        return __awaiter(this, void 0, void 0, function* () {
            const showSeriesURL = [__classPrivateFieldGet(this, _baseURL), "series", series].join("/");
            log(`opening ${showSeriesURL}`, true);
            yield this.page.goto(showSeriesURL);
            let seriesSelector = `//*[contains(text(), "${series}")]`;
            yield this.page.waitForXPath(seriesSelector);
            log(`opened ${showSeriesURL}`, true);
        });
    }
    openAddEpisodePage(series, season) {
        return __awaiter(this, void 0, void 0, function* () {
            log("opening addEpisodePage", true);
            try {
                yield this.openSeriesSeasonPage(series, season);
            }
            catch (_a) {
                yield this.addSeriesSeason(series, season);
                yield this.openSeriesSeasonPage(series, season);
            }
            const addEpisodeSelector = '//*[contains(text(),"Add Episode")]';
            yield this.page.waitForXPath(addEpisodeSelector, { visible: true });
            const addEpisodeButton = yield this.page.$x(addEpisodeSelector);
            yield addEpisodeButton[0].click();
            log("opened addEpisodePage", true);
        });
    }
    openEditEpisodePage(series, season, episode) {
        return __awaiter(this, void 0, void 0, function* () {
            const episodeTitle = episode.title();
            log(`opening editEpisodePage ${episodeTitle}`, true);
            yield delay(500);
            yield this.openSeriesSeasonPage(series, season);
            const episodeLink = yield this.page.$x(this.getEpisodeXpath(episode.title()));
            yield episodeLink[0].click();
            const editEpisodeButtonSelector = '//*[contains(text(),"Edit Episode")]';
            const editEpisodeButton = yield this.page.$x(editEpisodeButtonSelector);
            yield editEpisodeButton[0].click();
            log(`opened editEpisodePage ${episodeTitle}`, true);
        });
    }
    addInitialEpisode(episode) {
        return __awaiter(this, void 0, void 0, function* () {
            const infoJson = episode.information();
            log(`starting adding`, true);
            const addEpisodeFormSelector = "//h3[text()='Episodes']/ancestor::form";
            yield this.page.waitForXPath(addEpisodeFormSelector);
            yield delay(500);
            yield this.page.$eval('[name="name[]"]', setHtmlInput, episode.title());
            yield this.page.$eval('[name="overview[]"]', setHtmlInput, infoJson.description());
            yield this.page.$eval('[name="runtime[]"]', setHtmlInput, infoJson.runTime());
            yield this.page.$eval('[name="date[]"]', setHtmlInput, infoJson.airedDate());
            yield delay(500);
            const addEpisodeFormElement = yield this.page.$x(addEpisodeFormSelector);
            yield this.page.evaluate(submitHtmlForm, addEpisodeFormElement[0]);
            log(`finished adding`, true);
        });
    }
    updateEpisode(episode) {
        return __awaiter(this, void 0, void 0, function* () {
            const infoJson = episode.information();
            log("updating episode", true);
            const editEpisodeFormSelector = "form.episode-edit-form";
            yield this.page.waitForSelector(editEpisodeFormSelector);
            yield delay(500);
            yield this.page.$eval("[name=productioncode]", setHtmlInput, infoJson.url());
            yield delay(500);
            const saveButtonSelector = "//button[text()='Save']";
            yield this.page.waitForXPath(saveButtonSelector);
            const saveButton = yield this.page.$x(saveButtonSelector);
            yield this.page.evaluate(clickHtmlElement, saveButton[0]);
            const episodeAddedSuccessfully = `//*[contains(text(),"${episode.title()}")]`;
            yield this.page.waitForXPath(episodeAddedSuccessfully);
            log("updated episode", true);
        });
    }
    uploadEpisodeThumbnail(episode) {
        return __awaiter(this, void 0, void 0, function* () {
            log("Starting image upload", true);
            const thumbnailPath = episode.thumbnailFilePath();
            const addArtworkSelector = "//a[text()='Add Artwork']";
            yield this.page.waitForXPath(addArtworkSelector, { visible: true });
            const addArtworkButton = yield this.page.$x(addArtworkSelector);
            yield this.page.evaluate(clickHtmlElement, addArtworkButton[0]);
            try {
                yield this.page.waitForSelector("input[type=file]");
                const elementHandle = yield this.page.$("input[type=file]");
                yield elementHandle.uploadFile(thumbnailPath);
                const continueButtonSelector = "//button[text()='Continue']";
                yield this.page.waitForXPath(continueButtonSelector);
                yield this.page.waitForTimeout(3000);
                const continueButton = yield this.page.$x(continueButtonSelector);
                yield this.page.evaluate(clickHtmlElement, continueButton[0]);
                const thumbnailAddedSelector = `//*[contains(text(),"${episode.title()}")]`;
                yield this.page.waitForXPath(thumbnailAddedSelector);
                log("Successfully uploaded image", true);
            }
            catch (e) {
                log(e);
                yield this.takeScreenshot();
                log("Failed image upload");
            }
        });
    }
    addEpisode(episode, series, season) {
        return __awaiter(this, void 0, void 0, function* () {
            log(`Starting adding of ${episode.name}`);
            yield this.openAddEpisodePage(series, season);
            yield this.addInitialEpisode(episode);
            try {
                const addEpisodeSelector = '//*[contains(text(),"Whoops, looks like something went wrong")]';
                yield this.page.waitForXPath(addEpisodeSelector);
                try {
                    yield this.openEditEpisodePage(series, season, episode);
                }
                catch (e) {
                    log(e);
                }
            }
            catch (_e) { }
            yield this.updateEpisode(episode);
            try {
                yield this.uploadEpisodeThumbnail(episode);
            }
            catch (e) {
                log(`sigh looks like they blocked images for ${series} (${e})`);
            }
            log(`Finished adding of ${episode.name}`);
        });
    }
}
_baseURL = new WeakMap();
export { TvdbSubmitter };
//# sourceMappingURL=TvdbSubmitter.js.map