import { TvdbSubmitter} from './models/submitter/TvdbSubmitter';
import {BaseSubmitter} from './models/submitter/BaseSubmitter';
import { Episode } from './models/Episode';
import { FileHandler } from './models/file/FileHandler';

class ShowSubmitter {
  email: string
  username: string
  password: string
  renameOnly: boolean
  folder: string
  submitters: Array<BaseSubmitter>

  constructor() {
    this.folder = "/tmp/episodes";
    this.renameOnly = false;
    this.submitters = [];
  }

  _parseArguments (): void {
    const inputs = process.argv.slice(2);
    for (let i = 0; i < inputs.length; i++) {
      const inputSplit = inputs[i].split('=');
      switch (inputSplit[0]) {
        case 'email':
          this.email = inputSplit[1];
          break;
        case 'password':
          this.password = inputSplit[1];
          break;
        case 'username':
          this.username = inputSplit[1];
          break;
        case 'renameOnly':
          this.renameOnly = inputSplit[1] == "true";
          break;
      }
    }
  }

  async _initSubmitters (): Promise<void> {
    this.submitters.push(new TvdbSubmitter(this.username, this.password, this.email));
    this.submitters.forEach(async (submitter: BaseSubmitter): Promise<void> => {
      await submitter.init();
      await submitter.doLogin();
    });
  }

  async _finishSubmitters (): Promise<void> {
    this.submitters.forEach(async (submitter: BaseSubmitter):  Promise<void> => {
      await submitter.finish();
    });
  }

  async _addEpisodes(fileToRename: string, series: string, season: string, episode: Episode): Promise<void> {
    this.submitters.forEach(async (submitter: BaseSubmitter): Promise<void> => {
      await submitter.openSeriesSeasonPage(series, season);
      const episodeTextIdentifier = await submitter.getEpisodeIdentifier(fileToRename);
      if (!this.renameOnly && episodeTextIdentifier.length == 0) {
        await submitter.addEpisode(episode, series, season);
      }
    });
  }

  async _verifyAddedEpisodes(fileToRename: string, series: string, season: string):  Promise<string> {
    let episodeTextIdentifier;
    try {
      this.submitters.forEach(async (submitter) => {
        await submitter.openSeriesSeasonPage(series, season);
        episodeTextIdentifier = await submitter.getEpisodeIdentifier(fileToRename);
        // if we cant find it on a source something went wrong
        if (episodeTextIdentifier.length == 0) {
          throw new Error;
        }
      });
    } catch (e) {}
    
    return episodeTextIdentifier;
  }

  async run (): Promise<void> {
    try {
      this._parseArguments();
      this._initSubmitters();
      const fileHandler = new FileHandler(this.folder);
      const shows = fileHandler.getFilesToProcess();
      for (const [series, seasons] of Object.entries(shows)) {
        for (const [season, episodes] of Object.entries(seasons)) {
          console.log(`Starting ${series} - season ${season}`);
          for (const episode of episodes) {
            const fileToRename = episode.name.substring(episode.name.indexOf(".") + 1);
            this._addEpisodes(fileToRename, series, season, episode);
            const finalFilename = await this._verifyAddedEpisodes(fileToRename, series, season);
            await fileHandler.renameEpisodeFiles(fileToRename, finalFilename, series, season);
          }
          console.log(`Finished ${series} - season ${season}`);
        }
      }
      this._finishSubmitters();
    } catch(e) {
      
    }
    
  }
}

export {ShowSubmitter};
