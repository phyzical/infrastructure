var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
import fs from "fs";
import puppeteer from "puppeteer";
import { ShowSubmitter } from "../../ShowSubmitter.js";
import { log } from "../../helpers/LogHelper.js";
import { currentFileTimestamp } from "../../helpers/GenericHelper.js";
class BaseSubmitter {
    constructor(username, password, email) {
        this.username = username;
        this.password = password;
        this.email = email;
    }
    doLogin() {
        throw new Error("Method not implemented.");
    }
    openSeriesSeasonPage(series, season) {
        throw new Error("Method not implemented.");
    }
    addSeriesSeason(series, season) {
        throw new Error("Method not implemented.");
    }
    openSeriesPage(series) {
        throw new Error("Method not implemented.");
    }
    addEpisode(episode, series, season) {
        throw new Error("Method not implemented.");
    }
    getEpisodeIdentifier(episodeTitle) {
        throw new Error("Method not implemented.");
    }
    init() {
        return __awaiter(this, void 0, void 0, function* () {
            this.browser = yield puppeteer.launch({
                args: [
                    // Required for Docker version of Puppeteer
                    "--no-sandbox",
                    "--disable-setuid-sandbox",
                    // This will write shared memory files into /tmp instead of /dev/shm,
                    // because Docker’s default for /dev/shm is 64MB
                    "--disable-dev-shm-usage",
                ],
            });
            const browserVersion = yield this.browser.version();
            log(`Started ${browserVersion}`);
            this.page = yield this.browser.newPage();
        });
    }
    finish(saveScreenshot = false) {
        return __awaiter(this, void 0, void 0, function* () {
            if (saveScreenshot) {
                yield this.takeScreenshot();
                yield this.saveHtml();
            }
            yield this.browser.close();
        });
    }
    saveHtml() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                const html = yield this.page.content();
                const filename = `${ShowSubmitter.folder}/html-${currentFileTimestamp()}-${this.constructor.name}`;
                const htmlPath = `${filename}.html`;
                fs.writeFileSync(htmlPath, html);
                log(`html can be found at ${htmlPath}`);
            }
            catch (e) {
                log(`failed to save html: ${e}`);
            }
        });
    }
    takeScreenshot() {
        return __awaiter(this, void 0, void 0, function* () {
            const filename = `${ShowSubmitter.folder}/screen-${currentFileTimestamp()}-${this.constructor.name}`;
            const screenshotPath = `${filename}.png`;
            try {
                yield this.page.screenshot({
                    path: screenshotPath,
                    fullPage: true,
                });
                log(`screen shot can be found at ${screenshotPath}`);
            }
            catch (e) {
                log(`failed to save screenshot: ${e}`);
            }
        });
    }
}
export { BaseSubmitter };
//# sourceMappingURL=BaseSubmitter.js.map