import { EpisodeInformation } from "../EpisodeInformation";

interface EpisodeInterface {
  informationFile: string;
  thumbnailFile: string;
  thumbnailFileTile: string;
  name: string;
  information(): EpisodeInformation;
}

export { EpisodeInterface };
