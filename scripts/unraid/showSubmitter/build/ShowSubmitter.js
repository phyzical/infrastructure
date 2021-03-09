var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
import { TvdbSubmitter } from './models/submitter/TvdbSubmitter.js';
import { FileHandler } from './models/file/FileHandler.js';
import { log } from './helpers/LogHelper.js';
class ShowSubmitter {
    constructor() {
        this.renameOnly = false;
        this.submitters = [];
    }
    parseArguments() {
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
    initSubmitters() {
        return __awaiter(this, void 0, void 0, function* () {
            this.submitters.push(new TvdbSubmitter(this.username, this.password, this.email));
            for (const submitter of this.submitters) {
                yield submitter.init();
                yield submitter.doLogin();
            }
        });
    }
    finishSubmitters() {
        return __awaiter(this, void 0, void 0, function* () {
            for (const submitter of this.submitters) {
                yield submitter.finish();
            }
        });
    }
    addEpisode(fileToRename, series, season, episode) {
        return __awaiter(this, void 0, void 0, function* () {
            for (const submitter of this.submitters) {
                yield submitter.openSeriesSeasonPage(series, season);
                const episodeTextIdentifier = yield submitter.getEpisodeIdentifier(fileToRename);
                if (!this.renameOnly && episodeTextIdentifier.length == 0) {
                    // await submitter.addEpisode(episode, series, season);
                }
            }
        });
    }
    verifyAddedEpisode(fileToRename, series, season) {
        return __awaiter(this, void 0, void 0, function* () {
            let episodeTextIdentifier;
            try {
                for (const submitter of this.submitters) {
                    yield submitter.openSeriesSeasonPage(series, season);
                    episodeTextIdentifier = yield submitter.getEpisodeIdentifier(fileToRename);
                    // if we cant find it on a source something went wrong
                    if (episodeTextIdentifier.length == 0) {
                        throw new Error;
                    }
                }
            }
            catch (e) {
                log(`Didnt add episode for ${fileToRename} something went horribly wrong!`);
            }
            return episodeTextIdentifier;
        });
    }
    addEpisodes() {
        return __awaiter(this, void 0, void 0, function* () {
            this.parseArguments();
            yield this.initSubmitters();
            const fileHandler = new FileHandler(ShowSubmitter.folder);
            const shows = fileHandler.getFilesToProcess();
            for (const [series, seasons] of Object.entries(shows)) {
                for (const [season, episodes] of Object.entries(seasons)) {
                    log(`Starting ${series} - ${season}`);
                    for (const episode of episodes) {
                        const fileToRename = episode.name.substring(episode.name.indexOf(".") + 1);
                        yield this.addEpisode(fileToRename, series, season, episode);
                        const finalFilename = yield this.verifyAddedEpisode(fileToRename, series, season);
                        yield fileHandler.renameEpisodeFiles(fileToRename, finalFilename, series, season);
                    }
                    log(`Finished ${series} - ${season}`);
                }
            }
            yield this.finishSubmitters();
        });
    }
    start() {
        this.addEpisodes().catch((e) => __awaiter(this, void 0, void 0, function* () {
            log(e);
            yield this.finishSubmitters().catch(e2 => {
                log(e2);
            });
        }));
    }
}
ShowSubmitter.folder = "/tmp/episodes";
export { ShowSubmitter };
//# sourceMappingURL=ShowSubmitter.js.map