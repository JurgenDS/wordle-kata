# Hello World Frontend

Angular 21 frontend application using standalone components, signals, modern Angular patterns, and **100% code coverage**.

## Architecture

This application follows modern Angular best practices:

- **Standalone Components**: No NgModules, fully standalone architecture
- **Signals**: Reactive state management using Angular Signals
- **OnPush Change Detection**: Optimized change detection strategy
- **Dependency Injection**: Using `inject()` function instead of constructor injection
- **Layer-Based Organization**:
  - `hello/hello-api.service.ts`: Data layer (API communication)
  - `hello/hello.component.ts`: Feature/presentation layer
  - `app.component.ts`: Root application component

## Technologies

- **Angular**: 21.0.0
- **TypeScript**: 5.9.3
- **RxJS**: 7.8.2
- **Cypress**: 15.7.0 (component testing)
- **ESLint**: 9.39.1 with angular-eslint 20.6.0
- **Prettier**: 3.6.2
- **Code Coverage**: @cypress/code-coverage 3.14.7 + NYC 17.1.0

## Code Coverage

**100% coverage** achieved using manual Istanbul instrumentation:

- **Statements**: 100% (22/22)
- **Branches**: 100% (0/0)
- **Functions**: 100% (5/5)
- **Lines**: 100% (20/20)

**Tests**: 10 Cypress component tests (3 service + 7 component)

**Implementation**: Custom Istanbul webpack loader for Angular 21 compatibility.
See [COVERAGE.md](./COVERAGE.md) for detailed setup documentation.

## Prerequisites

- Node.js 20+ (recommended)
- npm 10+

## Setup

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

## Running the Application

Start the development server:

```bash
npm start
```

The application will be available at `http://localhost:4200`

**Note:** Make sure the backend is running on `http://localhost:8080` before using the application.

## Environment Configuration

The API URL is externalized via Angular environment files for flexible deployment.

### Configuration Files

- **Development**: `src/environments/environment.ts` → `http://localhost:8080/api`
- **Production**: `src/environments/environment.prod.ts` → `/api` (relative URL, same domain)

### Build Configurations

**Development build** (default):
```bash
npm start
# Uses environment.ts with http://localhost:8080/api
```

**Production build**:
```bash
npm run build
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

### Run tests with coverage (headless):

```bash
npm run test:coverage
```

This will:
- Run all 10 Cypress component tests
- Generate coverage report
- Display coverage summary in terminal

### View HTML coverage report:

```bash
open coverage/index.html
```

### Run tests only (no coverage):

```bash
npm test
```

### Open Cypress Test Runner (interactive mode):

```bash
npm run test:open
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
npm run lint
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
npm run format:check
```

Auto-fix formatting:

```bash
npm run format
```

Prettier is configured for:
- TypeScript (`.ts`)
- HTML templates (`.html`)
- Styles (`.scss`, `.css`)
- JSON files (`.json`)

## Building for Production

Build the application:

```bash
npm run build
```

Build output will be in `dist/hello-world-frontend/` directory.

## Project Structure

```
frontend/
├── src/
│   ├── app/
│   │   ├── hello/
│   │   │   ├── hello-api.service.ts       # API service (data layer)
│   │   │   ├── hello-api.service.cy.ts    # Service tests (3 tests)
│   │   │   ├── hello.component.ts         # Feature component
│   │   │   ├── hello.component.html       # Component template
│   │   │   ├── hello.component.scss       # Component styles
│   │   │   └── hello.component.cy.ts      # Component tests (7 tests)
│   │   └── app.component.ts               # Root component
│   ├── main.ts                            # Application bootstrap
│   ├── index.html                         # HTML entry point
│   └── styles.scss                        # Global styles
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
├── angular.json                            # Angular CLI configuration
├── cypress.config.ts                       # Cypress configuration
├── cypress.webpack.config.js               # Custom webpack for coverage
├── tsconfig.json                           # TypeScript configuration
├── eslint.config.mjs                       # ESLint configuration
├── .prettierrc                             # Prettier configuration
├── package.json                            # Dependencies and scripts
├── COVERAGE.md                             # Coverage setup documentation
└── README.md                               # This file
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
npm run lint -- --fix
```

### Formatting issues

Auto-fix with Prettier:
```bash
npm run format
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
