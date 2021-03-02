import fs from 'fs';
import { Episode } from '../Episode';

class FileHandler {
  folder:string

  constructor(folder: string){
    this.folder = folder;
  }

  _getDirectories (source: string): Array<string> {
    return fs.readdirSync(source, {
      withFileTypes: true
    })
    .filter(dirent => dirent.isDirectory())
    .map(dirent => dirent.name);
  }


  _fileAccumulator(acc: Array<string>, file: string): Array<string> {
    const firstCharToNum = <number><unknown>file[0];
    if (!isNaN(firstCharToNum) && file.includes('.mp4')) {
      acc.push(file.replace('.mp4', ""));
    }
    return acc;
  }

  _seriesAccumulator (seriesAcc: Record<string, unknown>, series: string): Record<string, unknown> {
    const seriesPath = [this.folder, series].join('/');
    const seasonAccumulator = (seasonAcc: Record<string, unknown>, season: string): Record<string, unknown> => {
      const seasonPath = [seriesPath, season].join('/');
      const files = fs.readdirSync(seasonPath);
      const episodeAccumulator = (key: string): Episode => {
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
        return episode;
      };
      seasonAcc[season] = files.reduce(this._fileAccumulator, []).map(episodeAccumulator);
      return seasonAcc;
    };
    seriesAcc[series] = this._getDirectories(seriesPath)
      .filter((dirName) => new RegExp(/season/i).test(dirName))
      .reduce(seasonAccumulator, {});
    return seriesAcc;
  }

  async renameEpisodeFiles (fileToRename: string, episodeText: string, series: string, season: string): Promise<void> {
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
  
  getFilesToProcess (): Record<string, unknown> {
    console.log("Collating episodes");
    const filesForProcessing = this._getDirectories(this.folder).reduce(this._seriesAccumulator, {});
    console.log("Collated episodes");
    return filesForProcessing;
  }
}

export {FileHandler};
