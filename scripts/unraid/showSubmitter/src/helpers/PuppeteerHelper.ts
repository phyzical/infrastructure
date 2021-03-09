const setHtmlInput = (el: Element, v: any): void =>
  ((<HTMLInputElement>el).value = v);

const submitHtmlForm = (form: Element): void  => (<HTMLFormElement>form).submit();
const clickHtmlElement = (button: Element): void  => (<HTMLFormElement>button).click();

export {
  setHtmlInput,
  submitHtmlForm,
  clickHtmlElement
};
