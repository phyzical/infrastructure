import { EpisodeInformation } from "./EpisodeInformation.js";
import { EpisodeInterface } from "../interfaces/EpisodeInterface.js";
import fs from "fs";

class Episode implements EpisodeInterface {
  information(): EpisodeInformation {
    return new EpisodeInformation(
      JSON.parse(fs.readFileSync(this.informationFile).toString())
    );
  }
  informationFile: string;
  thumbnailFile: string;
  thumbnailFileTile: string;
  name: string;
}

export { Episode };
