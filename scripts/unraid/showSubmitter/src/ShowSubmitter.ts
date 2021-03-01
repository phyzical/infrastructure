import {TvdbSubmitter} from './submitter/TvdbSubmitter';
import fs from 'fs';
import {BaseSubmitter} from './submitter/BaseSubmitter';
import { Episode } from './Episode';

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
    this.submitters = [
      TvdbSubmitter
    ];
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

  _getDirectories (source: string): Array<string> {
    return fs.readdirSync(source, {
      withFileTypes: true
    })
    .filter(dirent => dirent.isDirectory())
    .map(dirent => dirent.name);
  }


  _fileAccumulator(acc: Array<string>, file: string): Array<string> {
    if (!isNaN(file[0]) && file.includes('.mp4')) {
      acc.push(file.replace('.mp4', ""));
    }
    return acc;
  }

  _seriesAccumulator (seriesAcc: Record<string, unknown>, series: string): Record<string, unknown> {
    const seriesPath = [this.folder, series].join('/');
    seriesAcc[series] = this._getDirectories(seriesPath).reduce((seasonAcc, season) => {
      if (season.includes('season') || season.includes('Season')) {
        const seasonPath = [seriesPath, season].join('/');
        const files = fs.readdirSync(seasonPath);
        seasonAcc[season] = files.reduce(this._fileAccumulator, []).map((key) => {
          const episode = new Episode();
          episode.informationFile = files.find(function (file) {
            return file.includes(key) && file.includes('.json');
          });

          episode.thumbnailFile = files.find(function (file) {
            return file.includes(key) && (file.includes('-screen.jpg') || file.includes('-thumb.jpg'));
          });

          // look for non thumb as backup
          episode.thumbnailFileTile = files.find(function (file) {
            return file.includes(key) && file.includes('.jpg');
          });

          if (!episode.thumbnailFile) {
            episode.thumbnailFile = episode.thumbnailFileTile;
          }
          console.log( episode.informationFile);
          //todo make sure the above has this.folder
          // return episode;
        });
      }
      return seasonAcc;
    }, {});
    return seriesAcc;
  }
  
  _getFilesToProcess (): Record<string, unknown> {
    console.log("Collating episodes");
    const filesForProcessing = this._getDirectories(this.folder).reduce(this._seriesAccumulator, {});
    console.log("Collated episodes");
    return filesForProcessing;
  }

  async _renameEpisodeFiles (fileToRename: string, episodeText: string, series: string, season: string): Promise<void> {
    console.log(`starting renaming ${fileToRename}`);
    const seasonFolder = [this.folder, series, season].join('/');
    const files = fs.readdirSync(seasonFolder);
    if (episodeText.length > 0) {
      files.forEach(function (file) {
        if (file.includes(`${fileToRename}.`) || file.includes(`${fileToRename}-`)) {
          const filePath = [seasonFolder, file].join('/');
          if (file.includes(".description") || file.includes(".json")) {
            fs.unlinkSync(filePath);
          } else {
            const newName = `${series.replace(/-/g,'.')}.${episodeText}${file.substring(file.indexOf("."))}`;
            fs.renameSync(filePath, [seasonFolder, newName].join('/'));
          }
        }
      });
    } else {
      console.log("renaming failed probably means it didn't get added correctly?");
      files.forEach(function (file) {
        if (file.includes(fileToRename)) {
          const errorDir = [seasonFolder, 'errored'].join('/');
          if (!fs.existsSync(errorDir)) {
            fs.mkdirSync(errorDir);
          }
          fs.renameSync([seasonFolder, file].join('/'), [errorDir, file].join('/'));
        }
      });
    }
    console.log("finished renaming");
  }

  async _initSubmitters (): Promise<void> {
    this.submitters.forEach(async (submitterClass: BaseSubmitter): Promise<void> => {
      const submitter = new submitterClass(this.username, this.password, this.email);
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
      const shows = await this._getFilesToProcess();
      for (const [series, seasons] of Object.entries(shows)) {
        for (const [season, episodes] of Object.entries(seasons)) {
          console.log(`Starting ${series} - season ${season}`);
          for (const episode of episodes) {
            const fileToRename = episode.name.substring(episode.name.indexOf(".") + 1);
            this._addEpisodes(fileToRename, series, season, episode);
            const finalFilename = await this._verifyAddedEpisodes(fileToRename, series, season);
            await this._renameEpisodeFiles(fileToRename, finalFilename, series, season);
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
