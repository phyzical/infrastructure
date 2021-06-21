var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
import fs from 'fs';
import { Episode } from '../Episode.js';
import { log } from '../../helpers/LogHelper.js';
class FileHandler {
    constructor(folder) {
        this.folder = folder;
    }
    getDirectories(source) {
        return fs.readdirSync(source, {
            withFileTypes: true
        })
            .filter(dirent => dirent.isDirectory())
            .map(dirent => dirent.name);
    }
    fileAccumulator(acc, file) {
        const firstCharToNum = file[0];
        // if first letter is a number assume its an unproccessed episode this means that
        // if we ever have shows that start with numbers we are screwed TODO check all chars before first . is numbers
        // this still wont work if the whole show is numbers though
        if (!isNaN(firstCharToNum) && file.includes('.mp4')) {
            acc.push(file.replace('.mp4', ""));
        }
        return acc;
    }
    renameEpisodeFiles(fileToRename, episodeText, series, season) {
        return __awaiter(this, void 0, void 0, function* () {
            log(`starting renaming ${fileToRename}`);
            const seasonFolder = [this.folder, series, season].join('/');
            const files = fs.readdirSync(seasonFolder);
            if (episodeText.length > 0) {
                files.forEach(function (file) {
                    if (file.includes(`${fileToRename}.`) || file.includes(`${fileToRename}-`)) {
                        const filePath = [seasonFolder, file].join('/');
                        if (file.includes(".description") || file.includes(".json")) {
                            fs.unlinkSync(filePath);
                        }
                        else {
                            const newName = `${series.replace(/-/g, '.')}.${episodeText}${file.substring(file.indexOf("."))}`;
                            fs.renameSync(filePath, [seasonFolder, newName].join('/'));
                        }
                    }
                });
            }
            else {
                log("renaming failed probably means it didn't get added correctly?");
                files.forEach(function (file) {
                    if (file.includes(fileToRename)) {
                        const errorDir = [seasonFolder, 'errored'].join('/');
                        if (!fs.existsSync(errorDir)) {
                            fs.mkdirSync(errorDir);
                        }
                        fs.renameSync([seasonFolder, file].join('/'), [errorDir, file].join('/'));
                    }
                });
            }
            log("finished renaming");
        });
    }
    getFilesToProcess() {
        log("Collating episodes");
        const directories = this.getDirectories(this.folder);
        const filesForProcessing = directories.reduce((seriesAcc, series) => {
            const seriesPath = [this.folder, series].join('/');
            const seasonAccumulator = (seasonAcc, season) => {
                const seasonPath = [seriesPath, season].join('/');
                const files = fs.readdirSync(seasonPath);
                const episodeAccumulator = (key) => {
                    const informationFile = files.find(function (file) {
                        return file.includes(key) && file.includes('.json');
                    });
                    let thumbnailFile = files.find(function (file) {
                        return file.includes(key) && (file.includes('-screen.jpg') || file.includes('-thumb.jpg'));
                    });
                    const thumbnailFileTile = files.find(function (file) {
                        return file.includes(key) && file.includes('.jpg');
                    });
                    if (!thumbnailFile) {
                        thumbnailFile = thumbnailFileTile;
                    }
                    const episode = new Episode();
                    episode.folder = seasonPath;
                    episode.informationFile = informationFile;
                    episode.thumbnailFile = thumbnailFile;
                    episode.thumbnailFileTile = thumbnailFileTile;
                    episode.name = key;
                    return episode;
                };
                seasonAcc[season] = files.reduce(this.fileAccumulator, []).map(episodeAccumulator);
                return seasonAcc;
            };
            seriesAcc[series] = this.getDirectories(seriesPath)
                .filter((dirName) => new RegExp(/season/i).test(dirName))
                .reduce(seasonAccumulator, {});
            return seriesAcc;
        }, {});
        log("Collated episodes");
        return filesForProcessing;
    }
}
export { FileHandler };
//# sourceMappingURL=FileHandler.js.map