import { EpisodeInformation } from "./EpisodeInformation.js";
import { EpisodeInterface } from "../interfaces/EpisodeInterface.js";
import fs from "fs";

class Episode implements EpisodeInterface {
  informationFile: string;
  thumbnailFile: string;
  thumbnailFileTile: string;
  folder: string;
  name: string;

  information(): EpisodeInformation {
    return new EpisodeInformation(
      JSON.parse(fs.readFileSync(this.informationFilePath()).toString())
    );
  }

  informationFilePath(): string {
    return [this.folder, this.informationFile].join('/')
  }

  thumbnailFilePath(): string {
    return [this.folder, this.thumbnailFile].join('/')
  }

  thumbnailFileTilePath(): string {
    return [this.folder, this.thumbnailFileTile].join('/')
  }

  
}

export { Episode };
