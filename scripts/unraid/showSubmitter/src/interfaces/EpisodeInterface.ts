import { EpisodeInformationInterface } from "./submitter/EpisodeInformationInterface.js";

interface EpisodeInterface {
  informationFile: string;
  thumbnailFile: string;
  thumbnailFileTile: string;
  name: string;
  folder: string;
  information(): EpisodeInformationInterface;
  informationFilePath(): string;
  thumbnailFilePath(): string;
  thumbnailTileFilePath(): string;
  title(): string;
}

export { EpisodeInterface };
