import { EpisodeInterface } from "./EpisodeInterface";

interface GenericSubmitterInterface {
  doLogin(): Promise<void>;
  openSeriesSeasonPage(series: string, season: string): Promise<void>;
  addEpisode(
    episode: EpisodeInterface,
    series: string,
    season: string
  ): Promise<void>;
  getEpisodeIdentifier(fileToRename: string): Promise<string>;
}

export { GenericSubmitterInterface };
