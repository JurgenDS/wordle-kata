# Wordle Kata Development Container

This directory contains the configuration for a VS Code Dev Container that provides a complete, consistent development environment for the Wordle Kata project.

## What's Included

### Languages & Runtimes
- **Java 21** (Eclipse Temurin) - For Spring Boot backend
- **Node.js 20 LTS** - For Angular frontend
- **pnpm** - Fast, disk space efficient package manager
- **Angular CLI** - For Angular development

### Build Tools
- **Maven 3.9.9** - For Java builds
- **pnpm** - For Node.js package management

### Quality & Security Tools
- **Gitleaks** - Secret scanning
- **Semgrep** - Static Application Security Testing (SAST)
- **license-checker** - NPM license compliance
- All Maven quality plugins (SpotBugs, Checkstyle, OWASP Dependency-Check, PIT)

### Testing Tools
- **JUnit 5** - Java unit testing
- **ArchUnit** - Architecture testing
- **JaCoCo** - Java code coverage
- **Cypress** - Frontend component testing
- **Playwright** - E2E testing (with browsers pre-installed)

### VS Code Extensions
- Java Extension Pack (Red Hat Java, Maven, Spring Boot)
- Angular Language Service
- ESLint & Prettier
- Playwright Test Explorer
- GitLens
- SonarLint
- Docker
- GitHub Copilot (if licensed)

## Pre-built Image

The devcontainer uses a **pre-built image** from GitLab Container Registry for fast startup:

```
registry.gitlab.com/simplificationofficers/wordle-kata/devcontainer:latest
```

This means team members don't need to build the image locally - they just pull and start coding!

## Getting Started

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- [VS Code](https://code.visualstudio.com/) with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### Opening in Dev Container

1. **Clone the repository** (if not already done):
   ```bash
   git clone git@gitlab.com:simplificationofficers/wordle-kata.git
   cd wordle-kata
   ```

2. **Login to GitLab Container Registry** (required to pull the pre-built image):
   ```bash
   docker login registry.gitlab.com
   ```
   Use your GitLab username and a [Personal Access Token](https://gitlab.com/-/user_settings/personal_access_tokens) with `read_registry` scope.

   > **Important**: Without this step, Docker cannot pull the pre-built image and will fall back to building locally (which takes 10-15 minutes).

3. **Open in VS Code**:
   ```bash
   code .
   ```

4. **Reopen in Container**:
   - Press `F1` and select "Dev Containers: Reopen in Container"
   - Or click the green button in the bottom-left corner and select "Reopen in Container"

5. **Wait for setup**:
   - The pre-built image will be pulled (~2-3 minutes)
   - Post-create scripts will install project dependencies
   - You'll see "SETUP COMPLETE!" when ready

### First Time Setup

On first run, the container automatically:
1. Installs frontend dependencies (`pnpm install`)
2. Installs E2E test dependencies
3. Installs Playwright browsers
4. Builds the backend (`mvn install`)
5. Configures shell aliases

## Quick Commands

After the container is ready, use these aliases:

| Command | Description |
|---------|-------------|
| `qc` | Run all quality checks |
| `qc-mutation` | Run quality checks with mutation testing |
| `be-run` | Start backend (port 8080) |
| `be-test` | Run backend tests |
| `be-build` | Build backend |
| `fe-start` | Start frontend (port 4200) |
| `fe-test` | Run frontend tests |
| `fe-lint` | Lint frontend code |
| `e2e-test` | Run E2E tests |
| `e2e-ui` | Run E2E tests with UI |
| `e2e-headed` | Run E2E tests in headed mode |

## Port Forwarding

The following ports are automatically forwarded:

| Port | Service |
|------|---------|
| 4200 | Angular dev server |
| 8080 | Spring Boot backend |
| 9323 | Playwright report server |
| 35729 | LiveReload |

## Environment Variables

### NVD API Key (Optional but Recommended)

For faster OWASP Dependency-Check scans, set your NVD API key:

1. Get a free API key from [NVD](https://nvd.nist.gov/developers/request-an-api-key)
2. Create `backend/.env`:
   ```
   NVD_API_KEY=your-api-key-here
   ```

The devcontainer will automatically load this file.

## Volume Mounts

The container uses named volumes for caches to improve performance:

- `wordle-kata-maven-cache` - Maven repository cache
- `wordle-kata-pnpm-cache` - pnpm store
- `wordle-kata-playwright-cache` - Playwright browsers

These persist across container rebuilds.

## Rebuilding the Container

If you need to rebuild (e.g., after Dockerfile changes):

1. Press `F1` → "Dev Containers: Rebuild Container"
2. Or "Dev Containers: Rebuild Without Cache" for a fresh build

## Troubleshooting

### Container fails to build
- Ensure Docker Desktop is running
- Try "Rebuild Without Cache"
- Check Docker has enough disk space (32GB+ recommended)

### Tests fail with permission errors
- Named volumes may have old permissions
- Run: `docker volume rm wordle-kata-maven-cache wordle-kata-pnpm-cache`
- Rebuild the container

### Slow first build
- First Maven build downloads all dependencies
- First Playwright run installs browsers
- Subsequent runs use cached volumes

### Out of memory
- Increase Docker memory limit to 8GB+ in Docker Desktop settings
- Or reduce `memory` in `docker-compose.yml`

## Building & Pushing the Image

### Automatic (CI/CD)

The GitLab CI pipeline automatically builds and pushes the image when:
- Files in `.devcontainer/` are changed on the `main` branch
- Manually triggered from the GitLab UI

### Manual Build & Push

For initial setup or local testing:

1. **Login to GitLab Container Registry**:
   ```bash
   docker login registry.gitlab.com
   ```
   Use your GitLab username and a [Personal Access Token](https://gitlab.com/-/user_settings/personal_access_tokens) with `read_registry` and `write_registry` scopes.

2. **Run the build script**:
   ```bash
   .devcontainer/build-and-push.sh
   ```

   Or with a specific tag:
   ```bash
   .devcontainer/build-and-push.sh v1.0.0
   ```

3. **Commit and push changes** to make the image available to the team.

### Manual Docker Commands

If you prefer manual commands:

```bash
cd .devcontainer

# Build
docker build -t registry.gitlab.com/simplificationofficers/wordle-kata/devcontainer:latest .

# Push
docker push registry.gitlab.com/simplificationofficers/wordle-kata/devcontainer:latest
```

## Files in This Directory

| File | Purpose |
|------|---------|
| `devcontainer.json` | Main configuration (features, extensions, settings) |
| `Dockerfile` | Container image definition |
| `docker-compose.yml` | Service configuration and volumes |
| `post-create.sh` | Runs once after container creation |
| `post-start.sh` | Runs every time container starts |
| `build-and-push.sh` | Script to build and push image to registry |
| `README.md` | This documentation |
