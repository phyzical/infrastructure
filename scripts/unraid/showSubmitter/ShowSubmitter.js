import TvdbSubmitter from './TvdbSubmitter'
const fs = require('fs');

class ShowSubmitter {
  email
  username
  password
  renameOnly = false
  folder = "/tmp/episodes"
  submitters = [
    TvdbSubmitter
  ]

  _parseArguments () {
    const inputs = process.argv.slice(2)
    for (let i = 0; i < inputs.length; i++) {
      const inputSplit = inputs[i].split('=')
      switch (inputSplit[0]) {
        case 'email':
          this.email = inputSplit[1]
          break;
        case 'password':
          this.password = inputSplit[1]
          break;
        case 'username':
          this.username = inputSplit[1]
          break
        case 'renameOnly':
          this.renameOnly = inputSplit[1] == "true"
          break;
      }
    }
  }

  _getDirectories (source) {
    return fs.readdirSync(source, {
      withFileTypes: true
    })
    .filter(dirent => dirent.isDirectory())
    .map(dirent => dirent.name)
  }


  _fileAccumulator(acc, file) {
    if (!isNaN(file[0]) && file.includes('.mp4')) {
      acc.push(file.replace('.mp4', ""))
    }
    return acc
  }

  _seriesAccumulator (seriesAcc, series) {
    const seriesPath = [this.folder, series].join('/')
    seriesAcc[series] = this._getDirectories(seriesPath).reduce((seasonAcc, season) => {
      if (season.includes('season') || season.includes('Season')) {
        const seasonPath = [seriesPath, season].join('/')
        const files = fs.readdirSync(seasonPath)
        seasonAcc[season] = files.reduce(this._fileAccumulator, []).map((key) => {
          const info = files.find(function (file) {
            return file.includes(key) && file.includes('.json')
          })

          const description = files.find(function (file) {
            return file.includes(key) && file.includes('.description')
          })

          let jpg = files.find(function (file) {
            return file.includes(key) && (file.includes('-screen.jpg') || file.includes('-thumb.jpg'))
          })

          // look for non thumb as backup
          const jpgTile = files.find(function (file) {
            return file.includes(key) && file.includes('.jpg')
          })

          if (!jpg) {
            jpg = jpgTile
          }

          return {
            info: [seasonPath, info].join('/'),
            description: [seasonPath, description].join('/'),
            jpg: [seasonPath, jpg].join('/'),
            jpgTile: [seasonPath, jpgTile].join('/'),
            name: key
          }
        })
      }
      return seasonAcc
    }, {})
    return seriesAcc
  }
  
  _getFilesToProcess () {
    console.log("Collating episodes")
    const filesForProcessing = this._getDirectories(this.folder).reduce(this._seriesAccumulator, {})
    console.log("Collated episodes")
    return filesForProcessing
  }

  async _renameEpisodeFiles (fileToRename, episodeText, series, season) {
    console.log(`starting renaming ${fileToRename}`)
    const seasonFolder = [this.folder, series, season].join('/')
    const files = fs.readdirSync(seasonFolder)
    if (episodeText.length > 0) {
      files.forEach(function (file) {
        if (file.includes(`${fileToRename}.`) || file.includes(`${fileToRename}-`)) {
          const filePath = [seasonFolder, file].join('/')
          if (file.includes(".description") || file.includes(".json")) {
            fs.unlinkSync(filePath)
          } else {
            const newName = `${series.replace(/-/g,'.')}.${episodeText}${file.substring(file.indexOf("."))}`
            fs.renameSync(filePath, [seasonFolder, newName].join('/'))
          }
        }
      })
    } else {
      console.log("renaming failed probaly means it didnt get added correctly?")
      files.forEach(function (file) {
        if (file.includes(fileToRename)) {
          const errorDir = [seasonFolder, 'errored'].join('/')
          if (!fs.existsSync(errorDir)) {
            fs.mkdirSync(errorDir);
          }
          fs.renameSync([seasonFolder, file].join('/'), [errorDir, file].join('/'))
        }
      })
    }
    console.log("finished renaming")
  }

  _initSubmitters () {
    this.submitters = this.submitters.map((submitterClass) => {
      let submitter = new submitterClass(this.username, this.password, this.email)
      await submitter.init();
      await submitter.doLogin();
      return submitter
    })
  }

  _finishSubmitters () {
    this.submitters = this.submitters.map((submitter) => {
      await submitter.finish();
      return submitter
    })
  }

  _addEpisodes(fileToRename, series, season, episode) {
    this.submitters.forEach((submitter) => {
      await submitter.openSeriesSeasonPage(series, season)
      const episodeTextIdentifier = await submitter.getEpisodeIdentifier(fileToRename)
      if (!this.renameOnly && episodeTextIdentifier.length == 0) {
        await submitter.addEpisode(this.folder, episode, series, season)
      }
    })

  }

  _verifyAddedEpisodes(fileToRename, series, season) {
    let episodeTextIdentifier
    this.submitters.forEach((submitter) => {
      await submitter.openSeriesSeasonPage(series, season)
      episodeTextIdentifier = await submitter.getEpisodeIdentifier(fileToRename)
      if (episodeTextIdentifier.length == 0) {
        break;
      }
    })
    return episodeTextIdentifier
  }

  run () {
    this._parseArguments()
    this._initSubmitters()
    const shows = await this._getFilesToProcess()
    for (const [series, seasons] of Object.entries(shows)) {
      for (const [season, episodes] of Object.entries(seasons)) {
        console.log(`Starting ${series} - season ${season}`)
        for (const episode of episodes) {
          const fileToRename = episode.name.substring(episode.name.indexOf(".") + 1)
          this._addEpisodes(fileToRename, series, season, episode)
          const finalFilename = this._verifyAddedEpisodes(fileToRename, series, season)
          await this._renameEpisodeFiles(fileToRename, finalFilename, series, season);
        }
        console.log(`Finished ${series} - season ${season}`)
      }
    }
    this._finishSubmitters()
  }
}

// todo this needs to be moved as it wont have context for error screenshot
new ShowSubmitter().run().catch(e => {
  console.log('Error: \n', e)
  submitter.finish()
})

