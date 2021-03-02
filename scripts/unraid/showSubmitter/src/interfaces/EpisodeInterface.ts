import { EpisodeInformationInterface } from "./submitter/EpisodeInformationInterface";

interface EpisodeInterface {
  informationFile: string;
  thumbnailFile: string;
  thumbnailFileTile: string;
  name: string;
  information(): EpisodeInformationInterface;
}

export { EpisodeInterface };
