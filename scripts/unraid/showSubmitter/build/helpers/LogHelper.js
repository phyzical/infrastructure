const verbose = false;
const log = (message, checkVerbosity = false) => {
  if (!checkVerbosity || verbose) {
    console.log(message);
  }
};
export { log };
//# sourceMappingURL=LogHelper.js.map
