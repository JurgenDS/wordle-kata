# Key Differences: upm-client → wordle-kata/frontend

## Architecture

| | upm-client | wordle-kata |
|--|-----------|-------------|
| **Structure** | Nx Monorepo | Single Angular app |
| **Angular** | v20.3.3 | v21.0.0 |
| **Build** | Nx + Vite | Angular CLI (esbuild) |
| **State** | PrimeNG, Transloco, RxJS | Signals + RxJS only |

## What You'll Miss Coming from upm-client

- **No Nx commands** - use `npm start`, `npm test` directly
- **No `@upm-ng/*` path aliases** - flat project structure
- **No PrimeNG, Transloco** - simpler components, no i18n
- **No library boundaries** - all code colocated in `src/app/`
- **No affected task targeting** - single project, no dependency graph

## Project Structure Comparison

**upm-client** (monorepo):
```
apps/
  upm-ng/             # Main application
  upm-ng-e2e/         # E2E tests
libs/
  app-config/         # Shared app config
  data/               # Data access layer
  feat/               # Feature libraries
  ui/                 # UI components library
  validators/         # Shared validation
```

**wordle-kata/frontend** (flat):
```
src/
  app/
    hello/            # Feature module
  environments/
  main.ts
  styles.scss
cypress/
  loaders/
  plugins/
  support/
```

## Cypress Testing Differences

| upm-client | wordle-kata |
|-----------|-------------|
| `nxComponentTestingPreset` | Custom webpack config |
| TestBed + helper modules | Direct Cypress stubs |
| Mochawesome + JUnit reports | nyc/Istanbul coverage |
| Per-library configs | Single `cypress.config.ts` |
| Centralized reporter config | Manual setup |

### upm-client Test Pattern
```typescript
beforeEach(() => {
  TestBed.configureTestingModule({
    imports: [getTranslocoTestModule({ langs: { nl } })],
  });
});
cy.mount(MyComponent, { componentProperties });
```

### wordle-kata Test Pattern
```typescript
// Direct Cypress stubs with sinon
cy.stub(service, 'method').returns(value);
cy.mount(MyComponent);
```

## Quick Commands

| Task | upm-client | wordle-kata |
|------|-----------|-------------|
| Start dev server | `nx serve upm-ng` | `npm start` |
| Run component tests | `npm run component-test-upm-ng` | `npm test` |
| Open Cypress | `npm run cy:open` | `npm run test:open` |
| Build | `npm run build` | `npm run build` |
| Lint | Per-library via Nx | `npm run lint` |

## Configuration Files

**Critical for wordle-kata**:
- `angular.json` - Build configuration
- `cypress.config.ts` - Cypress component testing config
- `cypress.webpack.config.js` - Custom webpack for coverage
- `tsconfig.json` - Strict TypeScript setup

**Not present** (vs upm-client):
- `nx.json`
- `project.json` per library
- Monorepo workspace structure

## Code Style

Both use modern Angular patterns:
- Standalone components
- OnPush change detection
- Signals for state (`signal<T>`)
- TypeScript strict mode

**wordle-kata example**:
```typescript
export class HelloComponent {
  private readonly helloApiService = inject(HelloApiService);
  readonly name = signal<string>('World');
  readonly greeting = signal<string | null>(null);
}
```

## Transition Tips

1. **Forget Nx commands** - Everything goes through npm scripts
2. **Simpler dependency injection** - No complex service setup needed
3. **More manual testing setup** - Less infrastructure, more straightforward
4. **Custom webpack config** - You manage coverage instrumentation directly
5. **Direct component mounting** - No TestBed helper modules, pure Cypress mount

## Summary

wordle-kata is **much simpler** - single app, no monorepo tooling, basic Angular signals for state. The Cypress setup is custom (webpack-based coverage) vs Nx-integrated. You'll write less boilerplate but manage config more directly.
