import { EpisodeInformation } from "./EpisodeInformation";
import { EpisodeInterface } from "./interfaces/EpisodeInterface";
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
