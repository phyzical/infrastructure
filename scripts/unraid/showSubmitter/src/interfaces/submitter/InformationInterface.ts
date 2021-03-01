import { InformationInterface } from "../youtube/InformationInterface";

interface EpisodeInformationInterface {
  informationJson: InformationInterface;
  description(): string;
  title(): string;
  url(): string;
  runTime(): string;
  airedDate(): string;
}

export { EpisodeInformationInterface };
