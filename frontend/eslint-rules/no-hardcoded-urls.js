/**
 * @fileoverview ESLint rule to detect hardcoded URLs (loose coupling)
 * @author Architecture Team
 */

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Disallow hardcoded URLs to maintain loose coupling',
      category: 'Best Practices',
      recommended: true,
    },
    messages: {
      hardcodedUrl:
        'Hardcoded URL detected: "{{url}}". ' +
        'URLs should be externalized via environment configuration. ' +
        'Use environment.ts/environment.prod.ts instead.',
    },
    schema: [],
  },

  create(context) {
    // Regex to match localhost or 127.0.0.1 URLs with ports
    const HARDCODED_URL_PATTERN = /https?:\/\/(?:localhost|127\.0\.0\.1):\d+/;

    return {
      Literal(node) {
        // Check string literals
        if (typeof node.value === 'string') {
          const match = node.value.match(HARDCODED_URL_PATTERN);
          if (match) {
            context.report({
              node,
              messageId: 'hardcodedUrl',
              data: {
                url: match[0],
              },
            });
          }
        }
      },

      TemplateElement(node) {
        // Check template string parts
        const text = node.value.raw || node.value.cooked;
        if (text) {
          const match = text.match(HARDCODED_URL_PATTERN);
          if (match) {
            context.report({
              node,
              messageId: 'hardcodedUrl',
              data: {
                url: match[0],
              },
            });
          }
        }
      },
    };
  },
};
