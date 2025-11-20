// Import commands.js using ES2015 syntax:
import './commands'

// Import Cypress code coverage
import '@cypress/code-coverage/support'

// Import Cypress Angular mount function
import { mount } from 'cypress/angular'

// Augment the Cypress namespace to include type definitions for custom commands
declare global {
  namespace Cypress {
    interface Chainable {
      mount: typeof mount
    }
  }
}

Cypress.Commands.add('mount', mount)
