# Hello World Frontend

Angular 21 frontend application using standalone components, signals, Nx workspace, modern Angular patterns, and **100% code coverage**.

## Architecture

This application follows modern Angular best practices:

- **Standalone Components**: No NgModules, fully standalone architecture
- **Signals**: Reactive state management using Angular Signals
- **OnPush Change Detection**: Optimized change detection strategy
- **Dependency Injection**: Using `inject()` function instead of constructor injection
- **Library-Based Organization**: Nx-style apps/ + libs/ structure with path aliases
  - `@wordle-kata/data-access`: Data layer (API services)
  - `@wordle-kata/feature-hello`: Feature components
  - `@wordle-kata/ui`: Shared UI components
  - `@wordle-kata/shell`: Application shell

## Technologies

- **Angular**: 21.0.0
- **TypeScript**: 5.9.3
- **RxJS**: 7.8.2
- **Nx**: 22.1.1 (hybrid mode with build caching)
- **PrimeNG**: 20.3.0 (UI component library)
- **PrimeIcons**: 7.0.0 (icon library)
- **Cypress**: 15.7.0 (component testing)
- **ESLint**: 9.39.1 with angular-eslint 20.6.0
- **Prettier**: 3.6.2
- **Code Coverage**: @cypress/code-coverage 3.14.7 + NYC 17.1.0

## Code Coverage

**100% coverage** achieved using manual Istanbul instrumentation:

- **Statements**: 100%
- **Branches**: 100%
- **Functions**: 100%
- **Lines**: 100%

**Tests**: 30 Cypress component tests

**Implementation**: Custom Istanbul webpack loader for Angular 21 compatibility.
See [COVERAGE.md](./COVERAGE.md) for detailed setup documentation.

## Prerequisites

- Node.js 20+ (recommended)
- pnpm 10+ (install via `npm install -g pnpm`)

## Setup

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Install dependencies:
   ```bash
   pnpm install
   ```

**Note:** This project uses **pnpm** for faster, more efficient dependency management. Do not use `npm` commands as they will create conflicting lock files.

## Running the Application

Start the development server:

```bash
pnpm start
```

The application will be available at `http://localhost:4200`

**Note:** Make sure the backend is running on `http://localhost:8080` before using the application.

## Environment Configuration

The API URL is externalized via Angular environment files for flexible deployment.

### Configuration Files

- **Development**: `apps/hello-world-frontend/src/environments/environment.ts` → `http://localhost:8080/api`
- **Production**: `apps/hello-world-frontend/src/environments/environment.prod.ts` → `/api` (relative URL, same domain)

### Build Configurations

**Development build** (default):
```bash
pnpm start
# Uses environment.ts with http://localhost:8080/api
```

**Production build**:
```bash
pnpm build
# Replaces environment.ts with environment.prod.ts
# Uses /api (relative URL for same-domain deployment)
```

### Implementation

The `HelloApiService` reads from the environment configuration:

```typescript
// environment.ts (development)
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8080/api'
};

// environment.prod.ts (production)
export const environment = {
  production: true,
  apiUrl: '/api'
};

// hello-api.service.ts
private readonly apiUrl = `${environment.apiUrl}/hello`;
```

File replacement is configured in `angular.json`:

```json
"configurations": {
  "production": {
    "fileReplacements": [{
      "replace": "src/environments/environment.ts",
      "with": "src/environments/environment.prod.ts"
    }]
  }
}
```

This ensures the frontend is **loosely coupled** from the backend - no hardcoded URLs in code.

## Running Tests

**Quick option:** Run all quality checks from project root with `./quality-check.sh` (macOS/Linux) or `quality-check.bat` (Windows).

### Run tests with coverage (headless):

```bash
pnpm test:coverage
```

This will:
- Run all 30 Cypress component tests
- Generate coverage report
- Display coverage summary in terminal

### View HTML coverage report:

```bash
open coverage/index.html
```

### Run tests only (no coverage):

```bash
pnpm test
```

### Open Cypress Test Runner (interactive mode):

```bash
pnpm test:open
```

This will open the Cypress UI where you can:
- Select and run individual component tests
- See tests run in real-time with visual feedback
- Debug test failures with time-travel debugging
- Inspect component state and DOM

## Code Quality

### Linting

Run ESLint to check code quality:

```bash
pnpm lint
```

ESLint is configured with:
- **angular-eslint 20.6.0**: Angular-specific rules
- **typescript-eslint 8.46.3**: TypeScript rules
- **Custom architecture rules**: Loose coupling enforcement
- Strict configuration for code quality

#### Custom ESLint Rules

**Loose Coupling Rule** (`custom/no-hardcoded-urls`):
- Detects hardcoded URLs (e.g., `http://localhost:8080`) in TypeScript files
- Enforces externalization via environment configuration
- Automatically excludes test files (`*.cy.ts`, `*.spec.ts`) and environment files
- Runs with every `npm run lint` execution

**Example violation:**
```
src/app/services/api.service.ts
  15:20  error  Hardcoded URL detected: "http://localhost:8080".
                URLs should be externalized via environment configuration.
                Use environment.ts/environment.prod.ts instead.
                custom/no-hardcoded-urls
```

**How to fix:**
1. Move URL to `src/environments/environment.ts`:
   ```typescript
   export const environment = {
     production: false,
     apiUrl: 'http://localhost:8080/api'
   };
   ```

2. Use environment configuration in service:
   ```typescript
   import { environment } from '../environments/environment';

   private readonly apiUrl = environment.apiUrl;
   ```

This ensures the frontend maintains **loose coupling** and can be deployed to different environments without code changes.

### Formatting

Check code formatting:

```bash
pnpm format:check
```

Auto-fix formatting:

```bash
pnpm format
```

Prettier is configured for:
- TypeScript (`.ts`)
- HTML templates (`.html`)
- Styles (`.scss`, `.css`)
- JSON files (`.json`)

## Building for Production

Build the application:

```bash
pnpm build
```

Build output will be in `dist/hello-world-frontend/` directory.

## Project Structure

```
frontend/
├── apps/
│   └── hello-world-frontend/
│       └── src/
│           ├── environments/
│           │   ├── environment.ts         # Development config
│           │   └── environment.prod.ts    # Production config
│           ├── main.ts                    # Application bootstrap
│           ├── index.html                 # HTML entry point
│           └── styles.scss                # Global styles
├── libs/
│   └── wordle/
│       ├── data-access/
│       │   └── src/
│       │       ├── index.ts               # Public API exports
│       │       └── lib/services/
│       │           ├── hello-api.service.ts    # API service
│       │           └── hello-api.service.cy.ts # Service tests (3 tests)
│       ├── feature-hello/
│       │   └── src/
│       │       ├── index.ts               # Public API exports
│       │       └── lib/
│       │           ├── hello.component.ts      # Feature component
│       │           ├── hello.component.html    # Component template
│       │           ├── hello.component.scss    # Component styles
│       │           └── hello.component.cy.ts   # Component tests (7 tests)
│       ├── ui/
│       │   └── src/
│       │       └── index.ts               # Shared UI components (placeholder)
│       └── shell/
│           └── src/
│               ├── index.ts               # Public API exports
│               └── lib/
│                   └── app.component.ts   # Root application component
├── eslint-rules/
│   ├── index.js                           # Custom ESLint plugin
│   └── no-hardcoded-urls.js               # Loose coupling rule
├── cypress/
│   ├── loaders/
│   │   └── istanbul-loader.js             # Custom Istanbul instrumentation
│   ├── plugins/
│   │   └── istanbul-transform.js          # Deprecated (kept for reference)
│   ├── support/
│   │   ├── component.ts                   # Cypress component setup
│   │   └── commands.ts                    # Custom Cypress commands
│   └── tsconfig.json                      # Cypress TypeScript config
├── coverage/                               # Coverage reports (generated)
├── .nycrc                                  # NYC coverage configuration
├── nx.json                                 # Nx workspace configuration
├── tsconfig.base.json                      # Base TypeScript config with path aliases
├── angular.json                            # Angular CLI configuration
├── cypress.config.ts                       # Cypress configuration
├── cypress.webpack.config.js               # Custom webpack for coverage
├── tsconfig.json                           # TypeScript configuration
├── eslint.config.mjs                       # ESLint configuration
├── .prettierrc                             # Prettier configuration
├── package.json                            # Dependencies and scripts (Nx-integrated)
├── COVERAGE.md                             # Coverage setup documentation
└── README.md                               # This file
```

## Nx Workspace

This project uses **Nx 22.1.1 in hybrid mode**, which means:
- Nx wraps Angular CLI commands for build caching
- All npm scripts still work (backward compatible)
- Nx caching enabled for `build`, `lint`, and `test` targets
- Future-ready for monorepo expansion

**Commands:**
```bash
# Using pnpm scripts (familiar)
pnpm start         # Runs: nx serve hello-world-frontend
pnpm build         # Runs: nx build hello-world-frontend
pnpm lint          # Runs: nx lint hello-world-frontend
pnpm test          # Runs: cypress run --component

# Direct Nx commands (advanced)
nx serve hello-world-frontend
nx build hello-world-frontend --configuration=production
nx lint hello-world-frontend
nx reset  # Clear Nx cache
```

**Path Aliases:**
All libraries use TypeScript path aliases configured in `tsconfig.base.json`:
- `@wordle-kata/data-access` → `libs/wordle/data-access/src/index.ts`
- `@wordle-kata/feature-hello` → `libs/wordle/feature-hello/src/index.ts`
- `@wordle-kata/ui` → `libs/wordle/ui/src/index.ts`
- `@wordle-kata/shell` → `libs/wordle/shell/src/index.ts`

## PrimeNG UI Library

**PrimeNG 20.3.0** is integrated and ready for use:
- 90+ production-ready Angular components
- Enterprise-grade UI components (data tables, forms, overlays, menus, charts, etc.)
- Excellent accessibility (WCAG 2.0 AA compliant)
- Comprehensive documentation at [primeng.org](https://primeng.org/)

**Note:** PrimeNG 20.3.0 uses a new theming system. For production usage, install the `@primeng/themes` package or use CDN links. See [PrimeNG theming docs](https://primeng.org/theming) for details.

**Example Usage:**
```typescript
import { ButtonModule } from 'primeng/button';
import { CardModule } from 'primeng/card';

@Component({
  standalone: true,
  imports: [ButtonModule, CardModule],
  template: `
    <p-card header="Title">
      <p>Content</p>
      <p-button label="Click Me"></p-button>
    </p-card>
  `
})
export class MyComponent { }
```

## Key Features

### Modern Angular Patterns

1. **Standalone Components**
   ```typescript
   @Component({
     selector: 'app-hello',
     standalone: true,
     imports: [CommonModule, FormsModule],
     // ...
   })
   ```

2. **Angular Signals**
   ```typescript
   readonly name = signal<string>('World');
   readonly greeting = signal<string | null>(null);
   readonly loading = signal<boolean>(false);
   readonly error = signal<string | null>(null);
   ```

3. **Inject Function**
   ```typescript
   private readonly helloApiService = inject(HelloApiService);
   ```

4. **Modern Control Flow (@if, @for)**
   ```html
   @if (loading()) {
     Loading...
   } @else {
     Get Greeting
   }
   ```

5. **OnPush Change Detection**
   ```typescript
   changeDetection: ChangeDetectionStrategy.OnPush
   ```

### API Integration

The `HelloApiService` communicates with the backend:

- **Base URL**: Configured via environment files (see [Environment Configuration](#environment-configuration))
  - Development: `http://localhost:8080/api/hello`
  - Production: `/api/hello` (relative URL)
- **Method**: GET
- **Parameters**: `name` (query parameter)
- **Response**: `{ message: string }`

## Component Behavior

### HelloComponent

**State (Signals):**
- `name`: Current name to greet (default: "World")
- `greeting`: Greeting message from backend (null when not loaded)
- `loading`: Loading state indicator (true during API call)
- `error`: Error message (null when no error)

**Methods:**
- `fetchGreeting()`: Calls backend API to get greeting
- `updateName(event)`: Updates name from input field

**User Flow:**
1. User enters name in input field
2. User clicks "Get Greeting" button
3. Loading state activates (button disabled)
4. API call to backend
5. Success: Display greeting message
6. Error: Display error message

## Testing Strategy

Tests follow the **AAA pattern** (Arrange-Act-Assert) with **Cypress Component Testing**:

### 1. Service Tests (`hello-api.service.cy.ts`) - 3 tests

- Mock HTTP requests with `HttpTestingController`
- Verify correct API calls and responses
- Use Cypress assertions (`expect().to.equal()`)
- Test sociably with real Angular TestBed

**Tests:**
- `should be created` - Service instantiation
- `should fetch greeting with custom name` - Custom parameter
- `should fetch greeting with default name` - Default parameter

### 2. Component Tests (`hello.component.cy.ts`) - 7 tests

- Mount components with `cy.mount()`
- Mock service dependencies with `cy.stub()`
- Test real DOM interactions and user flows
- Verify signal updates through UI changes
- Use Cypress selectors for robust element queries

**Tests:**
- `should mount the component` - Basic rendering
- `should display default name in input field` - Initial state
- `should update name when input changes` - User input
- `should fetch greeting successfully when button clicked` - Success flow
- `should display error when API call fails` - Error handling
- `should show loading state during API call` - Loading state
- `should clear error when making new request` - Error recovery

### Coverage Implementation

**Challenge**: Angular 21 uses esbuild, standard coverage tools incompatible

**Solution**: Custom Istanbul webpack loader

**Key Files:**
- `cypress.webpack.config.js` - Webpack configuration
- `cypress/loaders/istanbul-loader.js` - Istanbul instrumentation
- `.nycrc` - NYC configuration with exclusions

**Excluded from coverage:**
- `main.ts` - Angular bootstrap (framework code)
- `app.component.ts` - Empty shell component (no business logic)
- Test files (`*.cy.ts`, `*.spec.ts`)

## Code Quality Standards

This project follows:

### Clean Code Principles
- Meaningful names
- Small functions (max 300 lines per file)
- Self-documenting code
- DRY principle
- SOLID principles

### Angular Best Practices
- Standalone components (no NgModules)
- Signals for state management
- OnPush change detection
- inject() for dependency injection
- Modern control flow syntax (@if, @for)
- Reactive programming with RxJS
- Type-safe HTTP client

### Testing Standards
- **100% code coverage** on business logic
- Behavior-focused tests (not implementation-focused)
- AAA pattern (Arrange-Act-Assert)
- Sociable testing (mock only HTTP calls)
- Collocated tests (`*.cy.ts` next to source files)
- Descriptive test names

### Code Style
- ESLint for code quality
- Prettier for formatting
- Consistent naming conventions
- TypeScript strict mode
- No `any` types

## Development Guidelines

### Naming Conventions

- **Files**: `kebab-case.component.ts`, `kebab-case.service.ts`
- **Tests**: `*.cy.ts` for Cypress component tests (collocated with source)
- **Classes**: `PascalCase` (HelloComponent, HelloApiService)
- **Variables/Functions**: `camelCase` (fetchGreeting, updateName)
- **Observables**: Suffix with `$` (if using observables directly)
- **Signals**: Use `readonly` for public signals

### Change Detection

All components use `ChangeDetectionStrategy.OnPush` for optimal performance.

### Dependency Injection

Use the `inject()` function instead of constructor injection:

```typescript
private readonly service = inject(MyService);
```

### State Management

Use Angular Signals for reactive state:

```typescript
readonly mySignal = signal<string>('initial value');

// Update
this.mySignal.set('new value');

// Read
const value = this.mySignal();
```

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## Common Issues

### Tests not finding coverage

Ensure the custom webpack configuration is loaded:
- Check `cypress.config.ts` has `webpackConfig` option
- Verify `cypress.webpack.config.js` exists
- Clear coverage: `rm -rf .nyc_output coverage`

### ESLint errors

Run auto-fix:
```bash
pnpm lint -- --fix
```

### Formatting issues

Auto-fix with Prettier:
```bash
pnpm format
```

### Application not connecting to backend

- Verify backend is running on `http://localhost:8080`
- Check browser console for CORS errors
- Ensure CORS is configured in backend (see backend README for `CORS_ALLOWED_ORIGINS` configuration)
- Verify environment file has correct API URL (`src/environments/environment.ts`)

## Further Documentation

- [Coverage Setup](./COVERAGE.md) - Detailed Istanbul instrumentation documentation
- [Main README](../README.md) - Full project documentation
- [Backend README](../backend/README.md) - Backend documentation
