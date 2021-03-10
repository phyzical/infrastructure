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
import { setHtmlInput, submitHtmlForm, clickHtmlElement } from '../../helpers/PuppeteerHelper.js';
import { log } from '../../helpers/LogHelper.js';
class TvdbSubmitter extends BaseSubmitter {
    constructor() {
        super(...arguments);
        _baseURL.set(this, "https://thetvdb.com");
    }
    getEpisodeIdentifier(fileToRename) {
        return __awaiter(this, void 0, void 0, function* () {
            log(`Looking for episode for ${fileToRename}`, true);
            const filenameCleaned = fileToRename
                .toLowerCase()
                .replace(/\\| |'|"|_|\/|-|\|/g, "");
            // Remove following chars from filename and document contexts ?'/|-*: \ And lowercase all chars to increase matching
            const episodeFinderSelector = `//tr[.//a[contains(translate(translate(translate(text(),"?_'/|-*: \\",""),'"',''),` +
                `'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') ,` +
                `'${filenameCleaned}')]]/td`;
            const episodeTextElement = yield this.page.$x(episodeFinderSelector);
            let episodeIdentifier = "";
            try {
                episodeIdentifier = yield this.page.evaluate((element) => element.textContent, episodeTextElement[0]);
                log(`Found episode for ${fileToRename}`, true);
            }
            catch (e) {
                log(`Didnt find episode for ${fileToRename}`, true);
            }
            return episodeIdentifier;
        });
    }
    doLogin() {
        return __awaiter(this, void 0, void 0, function* () {
            log("starting login", true);
            const loginURL = [__classPrivateFieldGet(this, _baseURL), "auth", "login"].join("/");
            yield this.page.goto(loginURL);
            // i accept is gone?
            // const iAcceptSelector = '//*[contains(text(),"I accept")]'
            // await page.waitFor(iAcceptSelector)
            // const iAcceptButton = await page.$x(iAcceptSelector)
            // await iAcceptButton[0].click()
            const loginFormSelector = 'form[action="/auth/login"]';
            yield this.page.waitForSelector(loginFormSelector);
            yield this.page.type('[name="email"]', this.email);
            yield this.page.type('[name="password"]', this.password);
            yield this.page.$eval(loginFormSelector, (form) => form.submit());
            const didLogInSelector = `//*[contains(text(),"${this.username}")]`;
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
    openAddEpisodePage(series, season) {
        return __awaiter(this, void 0, void 0, function* () {
            log("opening addEpisodePage", true);
            yield this.openSeriesSeasonPage(series, season);
            const addEpisodeSelector = '//*[contains(text(),"Add Episode")]';
            yield this.page.waitForXPath(addEpisodeSelector);
            const addEpisodeButton = yield this.page.$x(addEpisodeSelector);
            yield addEpisodeButton[0].click();
            log("opened addEpisodePage", true);
        });
    }
    addInitialEpisode(episode) {
        return __awaiter(this, void 0, void 0, function* () {
            const infoJson = episode.information();
            log(`starting adding`, true);
            const addEpisodeFormSelector = "//h3[text()='Episodes']/ancestor::form";
            yield this.page.waitForXPath(addEpisodeFormSelector);
            yield this.page.$eval('[name="name[]"]', setHtmlInput, episode.title());
            yield this.page.$eval('[name="overview[]"]', setHtmlInput, infoJson.description());
            yield this.page.$eval('[name="runtime[]"]', setHtmlInput, infoJson.runTime());
            yield this.page.$eval('[name="date[]"]', setHtmlInput, infoJson.airedDate());
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
            yield this.page.$eval("[name=productioncode]", setHtmlInput, infoJson.url());
            const saveButtonSelector = "//button[text()='Save']";
            yield this.page.waitForXPath(saveButtonSelector);
            const saveButton = yield this.page.$x(saveButtonSelector);
            yield this.page.evaluate(clickHtmlElement, saveButton[0]);
            // await this.page.$eval(editEpisodeFormSelector, submitHtmlForm);
            const episodeAddedSuccessfully = '//*[contains(text(),"Episode was successfully updated!")]';
            yield this.page.waitForXPath(episodeAddedSuccessfully);
            log("updated episode", true);
        });
    }
    uploadEpisodeThumbnail(episode) {
        return __awaiter(this, void 0, void 0, function* () {
            log("Starting image upload", true);
            const thumbnailPath = episode.thumbnailFilePath();
            const addArtworkButton = yield this.page.$x("//a[text()='Add Artwork']");
            yield this.page.evaluate(clickHtmlElement, addArtworkButton[0]);
            try {
                yield this.page.waitForSelector("input[type=file]");
                const elementHandle = yield this.page.$("input[type=file]");
                yield elementHandle.uploadFile(thumbnailPath);
                const continueButtonSelector = "//button[text()='Continue']";
                yield this.page.waitForXPath(continueButtonSelector, {
                    timeout: 10000,
                });
                const continueButton = yield this.page.$x(continueButtonSelector);
                yield this.page.evaluate(clickHtmlElement, continueButton[0]);
                const saveButtonSelector = "//button[text()='Finish']";
                yield this.page.waitForXPath(saveButtonSelector, {
                    timeout: 10000,
                });
                const saveButton = yield this.page.$x(saveButtonSelector);
                yield this.page.evaluate(clickHtmlElement, saveButton[0]);
                const episodeAddedSuccessfully = '//*[contains(text(),"Artwork successfully added.")]';
                yield this.page.waitForXPath(episodeAddedSuccessfully, {
                    timeout: 70000,
                });
                log("Successfully uploaded image", true);
            }
            catch (e) {
                log(e);
                yield this.takeScreenshot();
                log("Failed image upload", true);
            }
        });
    }
    addEpisode(episode, series, season) {
        return __awaiter(this, void 0, void 0, function* () {
            log(`Starting adding of ${episode.name}`);
            yield this.openAddEpisodePage(series, season);
            yield this.addInitialEpisode(episode);
            yield this.updateEpisode(episode);
            //todo this still isnt working
            yield this.uploadEpisodeThumbnail(episode);
            log(`Finished adding of ${episode.name}`);
        });
    }
}
_baseURL = new WeakMap();
export { TvdbSubmitter };
//# sourceMappingURL=TvdbSubmitter.js.map