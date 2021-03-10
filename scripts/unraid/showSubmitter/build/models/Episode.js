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
        let thumbnailPath = this.thumbnailFile;
        if (!thumbnailPath) {
            thumbnailPath = this.thumbnailFileTile;
        }
        return [this.folder, thumbnailPath].join('/');
    }
}
export { Episode };
//# sourceMappingURL=Episode.js.map