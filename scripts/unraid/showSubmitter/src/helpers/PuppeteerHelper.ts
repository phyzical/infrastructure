const setHtmlInput = (el: Element, v: any): void =>
  ((<HTMLInputElement>el).value = v);

const submitHtmlForm = (form: Element): void  => (<HTMLFormElement>form).submit();

export {
  setHtmlInput,
  submitHtmlForm
};
