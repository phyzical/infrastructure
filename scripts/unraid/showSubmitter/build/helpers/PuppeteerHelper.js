System.register([], function (exports_1, context_1) {
    "use strict";
    var setHtmlInput, submitHtmlForm;
    var __moduleName = context_1 && context_1.id;
    return {
        setters: [],
        execute: function () {
            setHtmlInput = (el, v) => (el.value = v);
            exports_1("setHtmlInput", setHtmlInput);
            submitHtmlForm = (form) => form.submit();
            exports_1("submitHtmlForm", submitHtmlForm);
        }
    };
});
//# sourceMappingURL=PuppeteerHelper.js.map