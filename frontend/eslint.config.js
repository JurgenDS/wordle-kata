// @ts-check
const eslint = require("@eslint/js");
const tseslint = require("typescript-eslint");
const angular = require("angular-eslint");
const customRules = require("./eslint-rules");

module.exports = tseslint.config(
  // Global ignores (applied to all configs)
  {
    ignores: [
      "**/node_modules/**",
      "**/dist/**",
      "**/.angular/**",
      "**/.nx/**",
      "**/coverage/**",
      "**/.nyc_output/**",
      "**/cypress/videos/**",
      "**/cypress/screenshots/**",
      "**/*.js.map",
      "**/*.d.ts",
    ],
  },
  {
    files: ["**/*.ts"],
    ignores: [
      "**/*.cy.ts",
      "**/*.spec.ts",
      "**/environments/**",
      "cypress/**",
    ],
    extends: [
      eslint.configs.recommended,
      ...tseslint.configs.recommended,
      // Stylistic rules disabled for performance (can be slow)
      // Re-enable if you need style checks: ...tseslint.configs.stylistic,
      ...angular.configs.tsRecommended,
    ],
    // Inline template processor - REQUIRED only if you have components with inline templates
    // PERFORMANCE: This is the main bottleneck - it compiles Angular templates (30-60s on first run)
    // SOLUTION: Use templateUrl instead of inline template strings for better performance
    // If you have NO inline templates, you can disable this: processor: undefined,
    // Currently disabled because all templates use templateUrl (see app.component.ts)
    // processor: angular.processInlineTemplates,
    plugins: {
      "custom": customRules,
    },
    rules: {
      "@angular-eslint/directive-selector": [
        "error",
        {
          type: "attribute",
          prefix: "app",
          style: "camelCase",
        },
      ],
      "@angular-eslint/component-selector": [
        "error",
        {
          type: "element",
          prefix: "app",
          style: "kebab-case",
        },
      ],
      "custom/no-hardcoded-urls": "error",
    },
  },
  {
    files: ["**/*.cy.ts", "**/*.spec.ts", "**/environments/**"],
    extends: [
      eslint.configs.recommended,
      ...tseslint.configs.recommended,
      // Stylistic rules disabled for performance (can be slow)
      // Re-enable if you need style checks: ...tseslint.configs.stylistic,
      ...angular.configs.tsRecommended,
    ],
    plugins: {
      "custom": customRules,
    },
    rules: {
      "@angular-eslint/directive-selector": [
        "error",
        {
          type: "attribute",
          prefix: "app",
          style: "camelCase",
        },
      ],
      "@angular-eslint/component-selector": [
        "error",
        {
          type: "element",
          prefix: "app",
          style: "kebab-case",
        },
      ],
      "custom/no-hardcoded-urls": "off",
      "@typescript-eslint/no-unused-expressions": "off",
    },
  },
  {
    files: ["**/*.html"],
    extends: [
      ...angular.configs.templateRecommended,
      ...angular.configs.templateAccessibility,
    ],
    rules: {},
  }
);
