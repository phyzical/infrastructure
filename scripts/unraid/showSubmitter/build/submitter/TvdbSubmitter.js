System.register(["./BaseSubmitter", "../helpers/PuppeteerHelper"], function (exports_1, context_1) {
    "use strict";
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
    var _baseURL, BaseSubmitter_1, PuppeteerHelper_1, TvdbSubmitter;
    var __moduleName = context_1 && context_1.id;
    return {
        setters: [
            function (BaseSubmitter_1_1) {
                BaseSubmitter_1 = BaseSubmitter_1_1;
            },
            function (PuppeteerHelper_1_1) {
                PuppeteerHelper_1 = PuppeteerHelper_1_1;
            }
        ],
        execute: function () {
            TvdbSubmitter = class TvdbSubmitter extends BaseSubmitter_1.BaseSubmitter {
                constructor() {
                    super(...arguments);
                    _baseURL.set(this, "https://thetvdb.com");
                }
                getEpisodeIdentifier(fileToRename) {
                    return __awaiter(this, void 0, void 0, function* () {
                        // Remove following chars from filename and document contexts ?'/|-*: \ And lowercase all chars to increase matching
                        const cleanedFilename = fileToRename
                            .toLowerCase()
                            .replace(/\\| |'|"|_|\/|-|\|/g, "");
                        const episodeFinderSelector = `//tr[.//a[contains(translate(translate(translate(text(),"?'/|-*: \\",""),'"',''),` +
                            `'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') ,` +
                            `'${cleanedFilename}')]]/td`;
                        const episodeTextElement = yield this.page.$x(episodeFinderSelector);
                        let episodeIdentifier = "";
                        try {
                            episodeIdentifier = yield this.page.evaluate((element) => element.textContent, episodeTextElement[0]);
                        }
                        catch (e) {
                            console.log(e);
                        }
                        return episodeIdentifier;
                    });
                }
                doLogin() {
                    return __awaiter(this, void 0, void 0, function* () {
                        console.log("starting login");
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
                        console.log("finishing login");
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
                        yield this.page.goto(showSeasonURL);
                        let seasonSelector = `//*[contains(text(), "Season ${seasonClean}")]`;
                        if (seasonClean == "0") {
                            seasonSelector = `//*[contains(text(), "Specials")]`;
                        }
                        yield this.page.waitForXPath(seasonSelector);
                    });
                }
                _openAddEpisodePage(series, season) {
                    return __awaiter(this, void 0, void 0, function* () {
                        yield this.openSeriesSeasonPage(series, season);
                        const addEpisodeSelector = '//*[contains(text(),"Add Episode")]';
                        yield this.page.waitForXPath(addEpisodeSelector);
                        const addEpisodeButton = yield this.page.$x(addEpisodeSelector);
                        yield addEpisodeButton[0].click();
                    });
                }
                _updateEpisode(infoJson, jpgFile) {
                    return __awaiter(this, void 0, void 0, function* () {
                        const editEpisodeFormSelector = "form.episode-edit-form";
                        yield this.page.waitForSelector(editEpisodeFormSelector);
                        yield this.page.$eval("[name=productioncode]", PuppeteerHelper_1.setHtmlInput, infoJson.url());
                        yield this.page.$eval("[name=airdate]", PuppeteerHelper_1.setHtmlInput, infoJson.airedDate());
                        yield this.page.$eval("[name=runtime]", PuppeteerHelper_1.setHtmlInput, infoJson.runTime());
                        yield this.page.waitForSelector("input[type=file]");
                        if (jpgFile) {
                            const elementHandle = yield this.page.$("input[type=file]");
                            yield elementHandle.uploadFile(jpgFile);
                        }
                        yield this.page.waitForTimeout(2000);
                        yield this.page.$eval(editEpisodeFormSelector, PuppeteerHelper_1.submitHtmlForm);
                        const episodeAddedSuccessfully = '//*[contains(text(),"Episode was successfully updated!")]';
                        yield this.page.waitForXPath(episodeAddedSuccessfully, {
                            timeout: 100000,
                        });
                    });
                }
                addEpisode(episode, series, season) {
                    return __awaiter(this, void 0, void 0, function* () {
                        console.log("adding episode", episode.name);
                        yield this._openAddEpisodePage(series, season);
                        const infoJson = episode.information();
                        const addEpisodeFormSelector = "form.episode-add-form";
                        yield this.page.waitForSelector(addEpisodeFormSelector);
                        yield this.page.$eval("[name=episodename]", PuppeteerHelper_1.setHtmlInput, infoJson.title());
                        yield this.page.$eval("[name=overview]", PuppeteerHelper_1.setHtmlInput, infoJson.description());
                        yield this.page.$eval(addEpisodeFormSelector, PuppeteerHelper_1.submitHtmlForm);
                        try {
                            yield this._updateEpisode(infoJson, episode.thumbnailFile);
                        }
                        catch (e) {
                            //try again with tile
                            try {
                                yield this._updateEpisode(infoJson, episode.thumbnailFileTile);
                            }
                            catch (e2) {
                                // otherwise dont bother with an image
                                yield this._updateEpisode(infoJson, null);
                            }
                        }
                        console.log("added episode");
                    });
                }
            };
            exports_1("TvdbSubmitter", TvdbSubmitter);
            _baseURL = new WeakMap();
        }
    };
});
//# sourceMappingURL=TvdbSubmitter.js.map