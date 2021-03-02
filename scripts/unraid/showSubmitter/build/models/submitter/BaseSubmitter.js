System.register(["puppeteer"], function (exports_1, context_1) {
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
    var puppeteer_1, BaseSubmitter;
    var __moduleName = context_1 && context_1.id;
    return {
        setters: [
            function (puppeteer_1_1) {
                puppeteer_1 = puppeteer_1_1;
            }
        ],
        execute: function () {
            BaseSubmitter = class BaseSubmitter {
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
                addEpisode(episode, series, season) {
                    throw new Error("Method not implemented.");
                }
                getEpisodeIdentifier(fileToRename) {
                    throw new Error("Method not implemented.");
                }
                init() {
                    return __awaiter(this, void 0, void 0, function* () {
                        this.browser = yield puppeteer_1.default.launch({
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
                        console.log(`Started ${browserVersion}`);
                        this.page = yield this.browser.newPage();
                    });
                }
                finish() {
                    return __awaiter(this, void 0, void 0, function* () {
                        const submitterName = this.constructor.name;
                        const nowDateString = new Date() //
                            .toJSON()
                            .slice(0, 10)
                            .replace(/-/g, "");
                        yield this.page.screenshot({
                            path: `/tmp/scripts/${nowDateString}-${submitterName}.png`,
                            fullPage: true,
                        });
                        yield this.browser.close();
                    });
                }
            };
            exports_1("BaseSubmitter", BaseSubmitter);
        }
    };
});
//# sourceMappingURL=BaseSubmitter.js.map