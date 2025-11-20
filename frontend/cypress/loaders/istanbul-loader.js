const { createInstrumenter } = require('istanbul-lib-instrument');
const { SourceMapConsumer, SourceMapGenerator } = require('source-map');

/**
 * Custom webpack loader for Istanbul code instrumentation
 * Instruments TypeScript/JavaScript code for code coverage collection
 */
module.exports = function istanbulLoader(source, sourceMap) {
  const options = {
    esModules: true,
    produceSourceMap: true,
    autoWrap: false,
    preserveComments: true,
    compact: false,
  };

  const instrumenter = createInstrumenter(options);
  const filename = this.resourcePath;

  try {
    // Instrument the code
    const instrumentedCode = instrumenter.instrumentSync(
      source,
      filename,
      sourceMap
    );

    // Get the generated source map
    const instrumentedSourceMap = instrumenter.lastSourceMap();

    // Return instrumented code with source map
    this.callback(null, instrumentedCode, instrumentedSourceMap);
  } catch (error) {
    console.error(`Failed to instrument ${filename}:`, error.message);
    // Return original code if instrumentation fails
    this.callback(null, source, sourceMap);
  }
};
