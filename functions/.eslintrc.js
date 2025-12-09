module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    ecmaVersion: 2018,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    "quotes": ["error", "double"],
    "linebreak-style": "off",
    "max-len": "off",
    "comma-dangle": "off",
    "indent": "off",
    "object-curly-spacing": "off",
  },
};
