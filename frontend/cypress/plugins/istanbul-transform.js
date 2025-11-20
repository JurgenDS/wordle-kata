const istanbulLibInstrument = require('istanbul-lib-instrument');
const { createTransformer } = require('istanbul-lib-instrument');

/**
 * Custom Cypress plugin to instrument TypeScript/JavaScript files for code coverage
 * Uses Istanbul programmatic API to instrument code on-the-fly
 */
module.exports = function setupIstanbulTransform(on, config) {
  // Create instrumenter with options for TypeScript support
  const instrumenter = createTransformer({
    produceSourceMap: true,
    esModules: true,
    compact: false,
    preserveComments: true
  });

  // Hook into file:preprocessor event to instrument code
  on('file:preprocessor', (file) => {
    // Only instrument source files, not test files or node_modules
    const shouldInstrument =
      file.filePath.includes('/src/') &&
      !file.filePath.includes('.cy.ts') &&
      !file.filePath.includes('.spec.ts') &&
      !file.filePath.includes('node_modules');

    if (!shouldInstrument) {
      return file;
    }

    // Read file content
    const fs = require('fs');
    const content = fs.readFileSync(file.filePath, 'utf8');

    // Instrument the code
    try {
      const instrumentedCode = instrumenter(content, file.filePath);

      // Write instrumented code to temporary file
      const outputPath = file.outputPath || file.filePath + '.instrumented';
      fs.writeFileSync(outputPath, instrumentedCode);

      file.outputPath = outputPath;
      return file;
    } catch (error) {
      console.error('Failed to instrument:', file.filePath, error);
      return file;
    }
  });

  return config;
};
