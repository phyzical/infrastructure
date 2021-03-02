System.register(["./EpisodeInformation", "fs"], function (exports_1, context_1) {
    "use strict";
    var EpisodeInformation_1, fs_1, Episode;
    var __moduleName = context_1 && context_1.id;
    return {
        setters: [
            function (EpisodeInformation_1_1) {
                EpisodeInformation_1 = EpisodeInformation_1_1;
            },
            function (fs_1_1) {
                fs_1 = fs_1_1;
            }
        ],
        execute: function () {
            Episode = class Episode {
                information() {
                    new EpisodeInformation_1.EpisodeInformation(JSON.parse(fs_1.default.readFileSync(this.informationFile).toString()));
                    throw new Error("Method not implemented.");
                }
            };
            exports_1("Episode", Episode);
        }
    };
});
//# sourceMappingURL=Episode.js.map