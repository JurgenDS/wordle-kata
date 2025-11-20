const { createTransformer } = require('istanbul-lib-instrument');

/**
 * Custom webpack configuration for Cypress component testing with code coverage
 * Adds Istanbul instrumentation to TypeScript files
 */
module.exports = {
  module: {
    rules: [
      {
        test: /\.ts$/,
        exclude: [
          /node_modules/,
          /\.cy\.ts$/,
          /\.spec\.ts$/,
        ],
        enforce: 'post',
        use: {
          loader: require.resolve('./cypress/loaders/istanbul-loader.js'),
        },
      },
    ],
  },
  resolve: {
    extensions: ['.ts', '.js'],
  },
};
