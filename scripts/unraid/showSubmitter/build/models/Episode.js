import { EpisodeInformation } from "./EpisodeInformation.js";
import fs from "fs";
class Episode {
    information() {
        new EpisodeInformation(JSON.parse(fs.readFileSync(this.informationFile).toString()));
        throw new Error("Method not implemented.");
    }
}
export { Episode };
//# sourceMappingURL=Episode.js.map