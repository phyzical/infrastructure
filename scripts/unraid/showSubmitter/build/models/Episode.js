import { EpisodeInformation } from "./EpisodeInformation.js";
import fs from "fs";
class Episode {
    information() {
        return new EpisodeInformation(JSON.parse(fs.readFileSync(this.informationFile).toString()));
    }
}
export { Episode };
//# sourceMappingURL=Episode.js.map