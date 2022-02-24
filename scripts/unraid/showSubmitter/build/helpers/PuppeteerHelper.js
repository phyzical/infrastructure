const setHtmlInput = (el, v) => (el.value = v);
const submitHtmlForm = (form) => form.submit();
const clickHtmlElement = (button) => button.click();
const delay = (time) => {
    return new Promise(function (resolve) {
        setTimeout(resolve, time);
    });
};
export { setHtmlInput, submitHtmlForm, clickHtmlElement, delay };
//# sourceMappingURL=PuppeteerHelper.js.map