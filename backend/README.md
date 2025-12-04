# Hello World Backend

Spring Boot backend following Hexagonal Architecture (Ports & Adapters) pattern with **100% code coverage** and **ArchUnit architecture testing**.

## Architecture

This application follows **Hexagonal Architecture** with these layers:

- **Domain Layer** (`domain/model`): Pure business objects (Greeting)
- **Application Layer** (`application`):
  - **Ports** (`ports/incoming`): Command interfaces (GetGreetingCommand)
  - **Processors**: Business logic implementation (GetGreetingProcessor)
- **Adapter Layer** (`adapter/incoming/rest`): REST API controllers (HelloController)
- **Configuration** (`config`): Cross-cutting concerns (CORS)

### Design Patterns

- **Command Processor Pattern**: Commands define operations, processors implement them
- **Either Pattern** (Vavr): Business errors returned as `Either<BusinessError, T>`
- **Value Objects**: Immutable domain objects (Greeting)
- **Fail-Fast Validation**: Domain objects validate in constructor

## Technologies

- **Java**: 21
- **Spring Boot**: 3.4.1
- **Maven**: 3.9+
- **Vavr**: 0.10.4 (functional programming)
- **Lombok**: 1.18.42 (boilerplate reduction)
- **JUnit 5**: 5.x (testing framework)
- **AssertJ**: 3.x (fluent assertions)
- **JaCoCo**: 0.8.12 (code coverage)
- **ArchUnit**: 1.3.0 (architecture testing)
- **SpotBugs**: 4.9.3.0 + FindSecBugs (static analysis & security scanning)
- **PITest**: 1.17.4 (mutation testing)

## Code Coverage

**100% coverage** achieved across all metrics:

- **Instructions**: 100% (137/137)
- **Branches**: 100% (6/6)
- **Lines**: 100% (25/25)
- **Methods**: 100% (11/11)
- **Classes**: 100% (5/5)

**Tests**: 23 total
- **9 behavior tests**: Unit and integration tests
- **13 ArchUnit architecture tests**: Rules enforcing hexagonal architecture
- **1 loose coupling test**: Source code scanner preventing hardcoded URLs

**Implementation**: JaCoCo with Lombok integration via `lombok.config`

## Prerequisites

- Java 21 (required for SpotBugs; Java 25 not yet supported)
- Maven 3.6+

## Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   mvn clean install
   ```

## Running the Application

Start the Spring Boot application using the Maven profile:

```bash
mvn -Prun
```

Or use the full command:

```bash
mvn spring-boot:run
```

The server will start on `http://localhost:8080`

**Note:** The `-Prun` profile is configured in pom.xml to execute `spring-boot:run` as its default goal.

## API Endpoints

### GET /api/hello

Get a greeting message.

**Query Parameters:**
- `name` (optional): Name to greet (default: "World")

**Example Requests:**

```bash
# Default greeting
curl http://localhost:8080/api/hello

# Custom name
curl http://localhost:8080/api/hello?name=Alice
```

**Example Success Response:**

```json
{
  "message": "Hello, Alice! Welcome to the world."
}
```

**Example Error Response:**

```bash
# Blank name
curl "http://localhost:8080/api/hello?name=   "
```

```json
{
  "message": "Name cannot be empty"
}
```

**Status Codes:**
- `200 OK`: Greeting retrieved successfully
- `400 Bad Request`: Invalid input (blank/whitespace-only name)

## Running Tests

### Run all tests:

```bash
mvn test
```

This will run:
- 9 behavior tests (unit + integration)
- 13 ArchUnit architecture tests
- 1 loose coupling test
- Generate JaCoCo coverage report

### Run tests with clean build:

```bash
mvn clean test
```

### Run specific test class:

```bash
# Behavior tests
mvn test -Dtest=GetGreetingProcessorTest
mvn test -Dtest=GreetingTest
mvn test -Dtest=HelloControllerIntegrationTest

# Architecture tests
mvn test -Dtest=HexagonalArchitectureTest
```

### View coverage report:

```bash
open target/site/jacoco/index.html
```

Or on Linux:
```bash
xdg-open target/site/jacoco/index.html
```

### Run mutation testing (optional):

PITest mutation testing validates test quality by introducing code mutations:

```bash
mvn pitest:mutationCoverage
```

View report: `open target/pit-reports/index.html`

**Note:** Requires Java 21. Run from project root with `./quality-check.sh --mutation` for full quality check including mutation testing.

## Test Suites

### 1. Behavior Tests (9 tests)

**Unit Tests:**
- `GreetingTest` (3 tests): Domain model validation
  - `should accept and store valid message`
  - `should reject blank message`
  - `should reject null message`

- `GetGreetingProcessorTest` (3 tests): Business logic
  - `should generate personalized greeting for valid name`
  - `should reject blank name`
  - `should reject whitespace-only name`

**Integration Tests:**
- `HelloControllerIntegrationTest` (3 tests): API endpoint behavior
  - `should provide default greeting when no name specified`
  - `should provide personalized greeting for given name`
  - `should reject blank name with error message`

**Test Pattern**: AAA (Arrange-Act-Assert) with BDD-style @DisplayName

### 2. Architecture Tests (13 tests)

**ArchUnit Rules** (`HexagonalArchitectureTest`, 13 tests):

1. **Layer Structure:**
   - Domain layer should not depend on application layer
   - Application layer should not depend on adapter layer
   - Dependency rule: inner layers don't depend on outer layers

2. **Naming Conventions:**
   - Ports should be named `*Command` or `*Port`
   - Processors should be named `*Processor`
   - Adapters should be named `*Controller` or `*Adapter`

3. **Annotations:**
   - Processors should be annotated with `@Component`
   - REST controllers should be annotated with `@RestController`
   - All classes in adapter layer should have Spring annotations

4. **Package Structure:**
   - Port interfaces should be in `ports` package
   - Domain models should be in `domain.model` package
   - REST controllers should be in `adapter.incoming.rest` package

5. **Domain Independence:**
   - Domain layer should not depend on Spring Framework
   - Domain layer should not use Lombok annotations (verified)

6. **Loose Coupling:**
   - No hardcoded URLs in source code (verified by ArchUnit)

### 3. Loose Coupling Test (1 test)

**Source Code Scanner** (`LooseCouplingTest`):

Scans all Java source files in `src/main/java` for hardcoded URLs:
- Detects patterns like `http://localhost:8080` or `https://127.0.0.1:3000`
- Fails with detailed violation messages showing file and line number
- Provides fix instructions: use `@Value("${property}")` and `application.yml`
- Ensures configuration is externalized, not hardcoded

**Example violation output:**
```
❌ com/example/hello/config/WebConfig.java:15 - Found hardcoded URL: "http://localhost:4200"

💡 How to fix:
  1. Move URL to src/main/resources/application.yml:
     my.service.url: ${MY_SERVICE_URL:http://localhost:8080}

  2. Inject using @Value annotation:
     @Value("${my.service.url}")
     private String serviceUrl;
```

This test runs automatically with `mvn test` and enforces loose coupling at the architecture level.

## Project Structure

```
backend/
├── src/
│   ├── main/
│   │   ├── java/com/example/hello/
│   │   │   ├── domain/model/           # Domain entities and value objects
│   │   │   │   └── Greeting.java
│   │   │   ├── application/
│   │   │   │   ├── CommandProcessor.java
│   │   │   │   ├── ports/incoming/     # Input port interfaces (Commands)
│   │   │   │   │   └── GetGreetingCommand.java
│   │   │   │   └── processors/         # Business logic (Command processors)
│   │   │   │       ├── BusinessError.java
│   │   │   │       └── GetGreetingProcessor.java
│   │   │   ├── adapter/incoming/rest/  # REST controllers
│   │   │   │   ├── HelloController.java
│   │   │   │   └── GreetingDto.java
│   │   │   ├── config/                 # Spring configuration
│   │   │   │   └── WebConfig.java
│   │   │   └── HelloWorldApplication.java
│   │   └── resources/
│   │       └── application.yml
│   └── test/
│       └── java/com/example/hello/     # Tests (mirrors main structure)
│           ├── architecture/
│           │   ├── HexagonalArchitectureTest.java
│           │   └── LooseCouplingTest.java
│           ├── domain/model/
│           │   └── GreetingTest.java
│           ├── application/processors/
│           │   └── GetGreetingProcessorTest.java
│           └── adapter/incoming/rest/
│               └── HelloControllerIntegrationTest.java
├── lombok.config                        # Lombok configuration for coverage
└── pom.xml                              # Maven configuration with JaCoCo + ArchUnit
```

## Key Files

### Domain Layer
- `domain/model/Greeting.java`: Immutable value object representing a greeting
  - Validates message is not blank
  - Fail-fast principle
  - Factory method pattern (`Greeting.of()`)

### Application Layer
- `application/ports/incoming/GetGreetingCommand.java`: Command to get greeting
- `application/processors/GetGreetingProcessor.java`: Business logic implementation
  - Validates name is not blank
  - Returns `Either<BusinessError, Greeting>` for type-safe error handling
- `application/processors/BusinessError.java`: Business error representation
- `application/CommandProcessor.java`: Generic command processor interface

### Adapter Layer
- `adapter/incoming/rest/HelloController.java`: REST API endpoint
  - Maps HTTP requests to commands
  - Handles Either pattern results
  - Returns appropriate HTTP status codes
- `adapter/incoming/rest/GreetingDto.java`: Data transfer object for responses

### Configuration
- `config/WebConfig.java`: CORS configuration for frontend integration

## CORS Configuration

CORS is externalized via environment variables for flexible deployment.

### Configuration

**Environment Variable**: `CORS_ALLOWED_ORIGINS`
- **Default**: `http://localhost:4200` (Angular development server)
- **Format**: Comma-separated list of allowed origins
- **Configured in**: `src/main/resources/application.yml`

**Allowed methods**: GET, POST, PUT, DELETE, OPTIONS

### Examples

**Development** (default):
```bash
mvn -Prun
# Uses default: http://localhost:4200
```

**Production** (custom origins):
```bash
export CORS_ALLOWED_ORIGINS=https://myapp.com,https://www.myapp.com
mvn -Prun
```

**Docker/Kubernetes**:
```yaml
env:
  - name: CORS_ALLOWED_ORIGINS
    value: "https://myapp.com,https://www.myapp.com"
```

### Implementation

CORS configuration is injected from `application.yml` into `WebConfig.java`:

```yaml
# application.yml
cors:
  allowed-origins: ${CORS_ALLOWED_ORIGINS:http://localhost:4200}
```

```java
// WebConfig.java
@Value("${cors.allowed-origins}")
private String allowedOrigins;
```

This ensures the backend is **loosely coupled** from the frontend - no hardcoded URLs in code.

## Code Coverage Configuration

### JaCoCo Setup

Coverage is configured in `pom.xml`:

```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.12</version>
    <configuration>
        <excludes>
            <exclude>**/HelloWorldApplication.class</exclude>
        </excludes>
    </configuration>
</plugin>
```

### Lombok Integration

Lombok-generated code is excluded via `lombok.config`:

```properties
lombok.addLombokGeneratedAnnotation = true
```

This adds `@Generated` annotation to Lombok-generated code, which JaCoCo automatically excludes.

### Coverage Exclusions

- `HelloWorldApplication.main()` - Framework bootstrap (excluded in pom.xml)
- Lombok-generated code - Constructors, getters, equals, hashCode (excluded via annotation)

## Code Quality Standards

This project follows:

### Clean Code Principles
- Meaningful names (intention-revealing)
- Small methods (max 300 lines per file)
- Single responsibility
- Self-documenting code
- DRY (Don't Repeat Yourself)
- SOLID principles

### Hexagonal Architecture Principles
- **Dependency inversion**: Dependencies point inward
- **Ports & Adapters**: Clear separation of concerns
- **Framework independence**: Domain layer is pure Java
- **Either pattern**: Type-safe error handling (no exceptions for business errors)
- **Enforced by ArchUnit**: 12 architecture rules validate structure

### Static Analysis & Security
- **SpotBugs**: Bug detection with max effort
- **FindSecBugs**: Security vulnerability scanning
- Run with `mvn verify`

### Testing Standards
- **100% code coverage** on business logic
- **Behavior-focused tests**: Test observable outcomes, not implementation
- **BDD-style naming**: @DisplayName with descriptive test names
- **AAA pattern**: Arrange-Act-Assert structure
- **Sociable testing**: Mock only external dependencies, use real collaborators
- **Architecture testing**: ArchUnit validates architectural rules

### Code Organization
- **Feature-based**: Group by domain feature, not by layer
- **Clear boundaries**: Distinct packages for domain, application, adapter
- **Collocated tests**: Test structure mirrors main structure
- **No circular dependencies**: Acyclic dependency graph

## Development Guidelines

### Adding New Features

1. **Define domain model** (if needed): Create value object in `domain/model`
2. **Create command**: Add interface in `application/ports/incoming`
3. **Implement processor**: Add business logic in `application/processors`
4. **Create adapter**: Add REST controller in `adapter/incoming/rest`
5. **Write tests**: Follow TDD with behavior-focused tests
6. **Run ArchUnit tests**: Ensure architecture rules are followed

### Testing Approach

**Test-Driven Development (TDD):**
1. RED: Write failing test
2. GREEN: Minimal code to pass
3. REFACTOR: Clean up code
4. Repeat

**Behavior-Focused:**
- Test WHAT the system does, not HOW
- Use descriptive @DisplayName annotations
- Focus on observable outcomes
- Avoid testing implementation details

### Error Handling

**Business Logic Errors:**
- Return `Either<BusinessError, T>`
- NO exceptions for expected business errors
- Exceptions only for unexpected technical errors

**Validation:**
- Fail-fast in constructors
- Domain objects always valid after construction
- Validate at boundaries (commands, API)

## Common Issues

### Port 8080 already in use

```bash
# Find process using port 8080
lsof -i :8080

# Kill the process
kill -9 <PID>
```

### Tests failing after changes

```bash
# Clean rebuild
mvn clean test

# Verify coverage
open target/site/jacoco/index.html
```

### ArchUnit tests failing

- Check package structure matches hexagonal architecture
- Verify naming conventions (Processor, Controller, Command)
- Ensure annotations are correct (@Component, @RestController)
- Check dependencies don't violate layer rules

### Coverage not 100%

- Check if new code is tested
- Verify Lombok code is excluded (lombok.config)
- Ensure framework code is excluded (pom.xml)
- Look at coverage report for uncovered lines

## Further Documentation

- [Main README](../README.md) - Full project documentation
- [Frontend README](../frontend/README.md) - Frontend documentation
- [Project Standards](../docs/project-standards-java-springboot-backend.md) - Detailed standards
