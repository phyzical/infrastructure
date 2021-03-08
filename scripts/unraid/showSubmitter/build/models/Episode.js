import { EpisodeInformation } from "./EpisodeInformation.js";
import fs from "fs";
class Episode {
    information() {
        return new EpisodeInformation(JSON.parse(fs.readFileSync(this.informationFilePath()).toString()));
    }
    informationFilePath() {
        return [this.folder, this.informationFile].join('/');
    }
    thumbnailFilePath() {
        return [this.folder, this.thumbnailFile].join('/');
    }
    thumbnailFileTilePath() {
        return [this.folder, this.thumbnailFileTile].join('/');
    }
}
export { Episode };
//# sourceMappingURL=Episode.js.map