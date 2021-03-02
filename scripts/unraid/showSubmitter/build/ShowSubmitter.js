System.register(["./models/submitter/TvdbSubmitter", "./models/file/FileHandler"], function (exports_1, context_1) {
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
    var TvdbSubmitter_1, FileHandler_1, ShowSubmitter;
    var __moduleName = context_1 && context_1.id;
    return {
        setters: [
            function (TvdbSubmitter_1_1) {
                TvdbSubmitter_1 = TvdbSubmitter_1_1;
            },
            function (FileHandler_1_1) {
                FileHandler_1 = FileHandler_1_1;
            }
        ],
        execute: function () {
            ShowSubmitter = class ShowSubmitter {
                constructor() {
                    this.folder = "/tmp/episodes";
                    this.renameOnly = false;
                    this.submitters = [];
                }
                _parseArguments() {
                    const inputs = process.argv.slice(2);
                    for (let i = 0; i < inputs.length; i++) {
                        const inputSplit = inputs[i].split('=');
                        switch (inputSplit[0]) {
                            case 'email':
                                this.email = inputSplit[1];
                                break;
                            case 'password':
                                this.password = inputSplit[1];
                                break;
                            case 'username':
                                this.username = inputSplit[1];
                                break;
                            case 'renameOnly':
                                this.renameOnly = inputSplit[1] == "true";
                                break;
                        }
                    }
                }
                _initSubmitters() {
                    return __awaiter(this, void 0, void 0, function* () {
                        this.submitters.push(new TvdbSubmitter_1.TvdbSubmitter(this.username, this.password, this.email));
                        this.submitters.forEach((submitter) => __awaiter(this, void 0, void 0, function* () {
                            yield submitter.init();
                            yield submitter.doLogin();
                        }));
                    });
                }
                _finishSubmitters() {
                    return __awaiter(this, void 0, void 0, function* () {
                        this.submitters.forEach((submitter) => __awaiter(this, void 0, void 0, function* () {
                            yield submitter.finish();
                        }));
                    });
                }
                _addEpisodes(fileToRename, series, season, episode) {
                    return __awaiter(this, void 0, void 0, function* () {
                        this.submitters.forEach((submitter) => __awaiter(this, void 0, void 0, function* () {
                            yield submitter.openSeriesSeasonPage(series, season);
                            const episodeTextIdentifier = yield submitter.getEpisodeIdentifier(fileToRename);
                            if (!this.renameOnly && episodeTextIdentifier.length == 0) {
                                yield submitter.addEpisode(episode, series, season);
                            }
                        }));
                    });
                }
                _verifyAddedEpisodes(fileToRename, series, season) {
                    return __awaiter(this, void 0, void 0, function* () {
                        let episodeTextIdentifier;
                        try {
                            this.submitters.forEach((submitter) => __awaiter(this, void 0, void 0, function* () {
                                yield submitter.openSeriesSeasonPage(series, season);
                                episodeTextIdentifier = yield submitter.getEpisodeIdentifier(fileToRename);
                                // if we cant find it on a source something went wrong
                                if (episodeTextIdentifier.length == 0) {
                                    throw new Error;
                                }
                            }));
                        }
                        catch (e) { }
                        return episodeTextIdentifier;
                    });
                }
                run() {
                    return __awaiter(this, void 0, void 0, function* () {
                        try {
                            this._parseArguments();
                            this._initSubmitters();
                            const fileHandler = new FileHandler_1.FileHandler(this.folder);
                            const shows = fileHandler.getFilesToProcess();
                            for (const [series, seasons] of Object.entries(shows)) {
                                for (const [season, episodes] of Object.entries(seasons)) {
                                    console.log(`Starting ${series} - season ${season}`);
                                    for (const episode of episodes) {
                                        const fileToRename = episode.name.substring(episode.name.indexOf(".") + 1);
                                        this._addEpisodes(fileToRename, series, season, episode);
                                        const finalFilename = yield this._verifyAddedEpisodes(fileToRename, series, season);
                                        yield fileHandler.renameEpisodeFiles(fileToRename, finalFilename, series, season);
                                    }
                                    console.log(`Finished ${series} - season ${season}`);
                                }
                            }
                            this._finishSubmitters();
                        }
                        catch (e) {
                        }
                    });
                }
            };
            exports_1("ShowSubmitter", ShowSubmitter);
        }
    };
});
//# sourceMappingURL=ShowSubmitter.js.map