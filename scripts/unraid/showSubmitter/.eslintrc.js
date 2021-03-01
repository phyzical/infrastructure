module.exports = {
  parser: "@typescript-eslint/parser", // Specifies the ESLint parser
  parserOptions: {
    ecmaVersion: 2020, // Allows for the parsing of modern ECMAScript features
    sourceType: "module", // Allows for the use of imports
  },
  env: {
    node: true,
  },
  extends: [
    "plugin:@typescript-eslint/recommended", // Uses the recommended rules from the @typescript-eslint/eslint-plugin
  ],
  rules: {
    semi: ["error", "always"],
    "max-len": ["error", { "code": 120 }],
    // "function-call-argument-newline": ["error", "always"],
    "newline-per-chained-call": ["error", { "ignoreChainWithDepth": 2 }]
  },
  root: true,
};
