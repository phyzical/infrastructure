const verbose = true
const log = (message: string, checkVerbosity: boolean = false): void => {
  if (!checkVerbosity || verbose) {
    console.log(message)
  }
}

export {log}
