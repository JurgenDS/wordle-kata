# Key Differences: upm-client → wordle-kata/frontend

## Architecture

| | upm-client | wordle-kata |
|--|-----------|-------------|
| **Structure** | Nx Monorepo | Nx Monorepo (hybrid mode) |
| **Angular** | v20.3.3 | v21.0.0 |
| **Build** | Nx + Vite | Nx + Angular CLI (esbuild) |
| **State** | PrimeNG, Transloco, RxJS | PrimeNG, Signals + RxJS |
| **UI Library** | PrimeNG | PrimeNG 20.3.0 |
| **Package Manage** | npm | pnpm |

## Similarities with upm-client ✅

After the Nx + PrimeNG migration, wordle-kata frontend now shares **many characteristics** with upm-client:

- ✅ **Nx workspace** - Nx 22.1.1 in hybrid mode (Angular CLI integration)
- ✅ **Library-based structure** - `apps/` + `libs/` organization
- ✅ **Path aliases** - `@wordle-kata/*` similar to `@upm-ng/*`
- ✅ **PrimeNG** - Same UI component library (v20.3.0)
- ✅ **Build caching** - Nx caching for build, lint, test targets
- ✅ **Modern Angular patterns** - Standalone components, signals, OnPush

## Key Remaining Differences

### What You'll Still Miss:
- **No Transloco** - No i18n/l10n support (English only)
- **No Vite** - Uses Angular CLI with esbuild (not Vite)
- **Simpler structure** - Single app, smaller monorepo
- **No affected task targeting** - Single project, no complex dependency graph
- **Cypress instead of Jest** - Component testing uses Cypress, not Jest

## Project Structure Comparison

**upm-client** (complex monorepo):
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

**wordle-kata/frontend** (simple monorepo):
```
apps/
  hello-world-frontend/
    src/
      environments/   # Environment configs
      main.ts         # Bootstrap
      index.html
      styles.scss
libs/
  wordle/
    data-access/      # API services (similar to upm-client data/)
    feature-hello/    # Feature components (similar to upm-client feat/)
    ui/               # Shared UI components (similar to upm-client ui/)
    shell/            # Application shell
cypress/
  loaders/
  support/
```

**Key Similarity**: Both use `apps/` + `libs/` structure with path aliases! The main difference is scale - upm-client has many more libraries.

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
| Start dev server | `nx serve upm-ng` | `npm start` (runs `nx serve`) ✅ |
| Run component tests | `npm run component-test-upm-ng` | `npm test` |
| Open Cypress | `npm run cy:open` | `npm run test:open` |
| Build | `npm run build` | `npm run build` (runs `nx build`) ✅ |
| Lint | Per-library via Nx | `npm run lint` (runs `nx lint`) ✅ |

**Note**: wordle-kata npm scripts now use Nx commands under the hood, providing the same caching benefits as upm-client!

## Configuration Files

**Critical for wordle-kata**:
- ✅ `nx.json` - Nx workspace configuration (NEW!)
- ✅ `tsconfig.base.json` - Base config with path aliases (NEW!)
- `angular.json` - Build configuration
- `cypress.config.ts` - Cypress component testing config
- `cypress.webpack.config.js` - Custom webpack for coverage
- `tsconfig.json` - TypeScript setup

**Still not present** (vs upm-client):
- `project.json` per library - wordle-kata uses simpler structure
- Transloco configuration
- Vite configuration

## Code Style

Both use modern Angular patterns:
- ✅ Standalone components
- ✅ OnPush change detection
- ✅ Signals for state (`signal<T>`)
- ✅ TypeScript strict mode
- ✅ `inject()` function instead of constructor injection

**wordle-kata example** (using path aliases):
```typescript
import { HelloApiService } from '@wordle-kata/data-access';

export class HelloComponent {
  private readonly helloApiService = inject(HelloApiService);
  readonly name = signal<string>('World');
  readonly greeting = signal<string | null>(null);
}
```

**upm-client example** (very similar):
```typescript
import { SomeService } from '@upm-ng/data';

export class SomeComponent {
  private readonly someService = inject(SomeService);
  readonly data = signal<Data | null>(null);
}
```

## Transition Tips

### Coming from upm-client to wordle-kata:

1. ✅ **Nx commands work the same** - Use npm scripts or direct `nx` commands
2. ✅ **Path aliases are similar** - `@wordle-kata/*` instead of `@upm-ng/*`
3. ✅ **Library structure is familiar** - data-access, feature-*, ui, shell
4. ✅ **PrimeNG is available** - Same component library you know
5. ⚠️ **No Transloco** - No i18n support, English only
6. ⚠️ **Custom webpack config** - You manage coverage instrumentation directly
7. ⚠️ **Simpler structure** - Fewer libraries, single app

### Quick Adaptation Guide:

| You're Used To | In wordle-kata |
|----------------|----------------|
| `@upm-ng/data` | `@wordle-kata/data-access` |
| `@upm-ng/feat/something` | `@wordle-kata/feature-something` |
| `@upm-ng/ui` | `@wordle-kata/ui` |
| `nx serve upm-ng` | `nx serve hello-world-frontend` or `npm start` |
| `nx build upm-ng` | `nx build hello-world-frontend` or `npm run build` |
| Transloco pipes | No i18n - hardcode strings |
| Jest tests | Cypress component tests |
| Vite build | Angular CLI + esbuild |

## Summary

**After the Nx + PrimeNG migration**, wordle-kata is now **very similar** to upm-client:
- ✅ Same Nx monorepo structure (apps/ + libs/)
- ✅ Same PrimeNG UI library
- ✅ Same path alias pattern
- ✅ Same build caching benefits
- ✅ Same modern Angular patterns

**Main differences**:
- ⚠️ Simpler scale (1 app, 4 libraries vs many)
- ⚠️ No Transloco (no i18n)
- ⚠️ Cypress instead of Jest for testing
- ⚠️ Angular CLI instead of Vite

**Transition difficulty: 2/10** - Very easy if you know upm-client! The concepts and workflows are almost identical.
