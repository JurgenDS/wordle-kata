# Frontend Code Coverage Setup

## Overview

This project uses **Cypress Component Testing** with **manual Istanbul instrumentation** to achieve 100% code coverage on Angular 21.

## Coverage Metrics

| Metric | Coverage |
|--------|----------|
| **Statements** | **100%** (22/22) |
| **Branches** | **100%** (0/0) |
| **Functions** | **100%** (5/5) |
| **Lines** | **100%** (20/20) |

## Architecture

### Challenge
Angular 21 uses esbuild instead of webpack, making standard code coverage instrumentation tools incompatible. The `@angular-builders/custom-webpack` package doesn't support Angular 21.

### Solution: Manual Istanbul Instrumentation
We implemented a custom webpack loader that instruments TypeScript code using Istanbul programmatically.

## Files Created

### 1. `cypress.webpack.config.js`
Custom webpack configuration for Cypress dev server that adds Istanbul instrumentation.

### 2. `cypress/loaders/istanbul-loader.js`
Custom webpack loader using `istanbul-lib-instrument` to instrument code on-the-fly.

### 3. Updated `cypress.config.ts`
Configured to use the custom webpack configuration:
```typescript
devServer: {
  framework: 'angular',
  bundler: 'webpack',
  webpackConfig: require('./cypress.webpack.config.js')
}
```

### 4. Updated `.nycrc`
Excluded framework boilerplate from coverage:
- `**/main.ts` - Angular bootstrap code (like backend's `main()` method)
- `**/app.component.ts` - Empty shell component with no business logic

## Coverage Breakdown

### Covered (100%)
- ✅ `hello-api.service.ts` - API service with HTTP client logic
- ✅ `hello.component.ts` - Main component with state management

### Excluded (Framework Boilerplate)
- 🔧 `main.ts` - Angular application bootstrap
- 🔧 `app.component.ts` - Root component container (no business logic)
- 🔧 `cypress.config.ts` - Cypress configuration

## Running Coverage

```bash
# Run tests with coverage
npm run test:coverage

# View HTML report
open coverage/index.html
```

## Tests

**10 Cypress Component Tests:**
- 3 tests for `HelloApiService`
- 7 tests for `HelloComponent`

All tests are **behavior-focused**, testing observable outcomes rather than implementation details.

## Dependencies Added

```json
{
  "@cypress/code-coverage": "^3.14.7",
  "@cypress/webpack-preprocessor": "^6.0.3",
  "istanbul-lib-instrument": "^6.0.3",
  "nyc": "^17.1.0",
  "source-map": "^0.7.4"
}
```

## Maintenance Notes

- **Instrumentation happens at webpack build time** during Cypress component testing
- Coverage data is collected by `@cypress/code-coverage` and reported by `nyc`
- The custom loader only instruments source files in `src/`, excluding test files
- HTML coverage report is generated in `coverage/` directory
