import { EpisodeInformation } from "./EpisodeInformation.js";
import { EpisodeInterface } from "../interfaces/EpisodeInterface.js";
import fs from "fs";

class Episode implements EpisodeInterface {
  information(): EpisodeInformation {
    new EpisodeInformation(
      JSON.parse(fs.readFileSync(this.informationFile).toString())
    );
    throw new Error("Method not implemented.");
  }
  informationFile: string;
  thumbnailFile: string;
  thumbnailFileTile: string;
  name: string;
}

export { Episode };
