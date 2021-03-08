import { TvdbSubmitter} from './models/submitter/TvdbSubmitter.js';
import {BaseSubmitter} from './models/submitter/BaseSubmitter.js';
import { Episode } from './models/Episode.js';
import { FileHandler } from './models/file/FileHandler.js';

class ShowSubmitter {
  static folder: string = "/tmp/episodes"

  email: string
  username: string
  password: string
  renameOnly: boolean
  submitters: Array<BaseSubmitter>

  constructor() {
    this.renameOnly = false;
    this.submitters = [];
  }

  private parseArguments (): void {
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

  private async initSubmitters (): Promise<void> {
    this.submitters.push(new TvdbSubmitter(this.username, this.password, this.email));
    for (const submitter of this.submitters) {
      await submitter.init();
      await submitter.doLogin();
    }
  }

  private async finishSubmitters (): Promise<void> {
    for (const submitter of this.submitters) {
      await submitter.finish();
    }
  }

  private async addEpisode(fileToRename: string, series: string, season: string, episode: Episode): Promise<void> {
    for (const submitter of this.submitters) {
      await submitter.openSeriesSeasonPage(series, season);
      const episodeTextIdentifier = await submitter.getEpisodeIdentifier(fileToRename);
      if (!this.renameOnly && episodeTextIdentifier.length == 0) {
        await submitter.addEpisode(episode, series, season);
      }
    }
  }

  private async verifyAddedEpisode(fileToRename: string, series: string, season: string):  Promise<string> {
    let episodeTextIdentifier;
    try {
      for (const submitter of this.submitters) {
        await submitter.openSeriesSeasonPage(series, season);
        episodeTextIdentifier = await submitter.getEpisodeIdentifier(fileToRename);
        // if we cant find it on a source something went wrong
        if (episodeTextIdentifier.length == 0) {
          throw new Error;
        }
      }
    } catch (e) {
      console.log(`Didnt add episode for ${fileToRename} something went horribly wrong!`)
    }
    
    return episodeTextIdentifier;
  }

  private async addEpisodes (): Promise<void> {
    this.parseArguments();
    await this.initSubmitters();
    const fileHandler = new FileHandler(ShowSubmitter.folder);
    const shows = fileHandler.getFilesToProcess();
    for (const [series, seasons] of Object.entries(shows)) {
      for (const [season, episodes] of Object.entries(seasons)) {
        console.log(`Starting ${series} - ${season}`);
        for (const episode of episodes) {
          const fileToRename = episode.name.substring(episode.name.indexOf(".") + 1);
          await this.addEpisode(fileToRename, series, season, episode);
          const finalFilename = await this.verifyAddedEpisode(fileToRename, series, season);
          await fileHandler.renameEpisodeFiles(fileToRename, finalFilename, series, season);
        }
        console.log(`Finished ${series} - ${season}`);
      }
    }
    await this.finishSubmitters();
  }

  start(): void {
    this.addEpisodes().catch(async e => {
      console.log(e)
      await this.finishSubmitters().catch(e2 => {
        console.log(e2)
      })
    })
  }
}

export {ShowSubmitter};
