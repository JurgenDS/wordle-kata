# Wordle Kata Development Container

A pre-built development container for instant coding - no local setup required!

## Quick Start (3 Steps)

### 1. Clone the Repository

```bash
git clone git@gitlab.com:simplificationofficers/wordle-kata.git
cd wordle-kata
```

### 2. Login to GitLab Container Registry

```bash
docker login registry.gitlab.com
```

Use your GitLab username and a [Personal Access Token](https://gitlab.com/-/user_settings/personal_access_tokens) with `read_registry` scope.

> **Important**: This step is required to pull the pre-built image. Without it, your IDE will attempt to build the image locally (which takes 10-15 minutes).

### 3. Open in Your IDE

#### VS Code

1. Install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. Open the project: `code .`
3. Click the green button in the bottom-left corner → "Reopen in Container"
   - Or press `F1` → "Dev Containers: Reopen in Container"

#### IntelliJ IDEA Ultimate

1. Open the project in IntelliJ IDEA Ultimate
2. IntelliJ will detect the `.devcontainer` configuration
3. Click "Create Dev Container" in the notification
   - Or go to **File → Remote Development → Dev Containers → Create Dev Container**
4. Select the project and click "Build Container and Continue"

### 4. Wait for Setup (~2-3 minutes)

The pre-built image will be pulled and post-create scripts will:
- Install frontend dependencies
- Install Playwright browsers
- Build the backend
- Configure shell aliases

You'll see "SETUP COMPLETE!" when ready.

---

## What's Included

### Languages & Runtimes
| Tool | Version | Purpose |
|------|---------|---------|
| Java | 21 (Eclipse Temurin) | Spring Boot backend |
| Node.js | 20 LTS | Angular frontend |
| Maven | 3.9.11 | Java builds |
| pnpm | Latest | Node.js package management |
| Angular CLI | Latest | Angular development |

### Quality & Security Tools
- **Gitleaks** - Secret scanning
- **Semgrep** - Static Application Security Testing (SAST)
- **SpotBugs** - Java static analysis
- **Checkstyle** - Java code style
- **OWASP Dependency-Check** - Vulnerability scanning
- **PIT** - Mutation testing

### Testing Tools
- **JUnit 5** - Java unit testing
- **ArchUnit** - Architecture testing
- **JaCoCo** - Java code coverage
- **Vitest** - Frontend unit testing
- **Playwright** - E2E testing (browsers pre-installed)

### IDE Extensions (VS Code)
- Java Extension Pack (Red Hat Java, Maven, Spring Boot)
- Angular Language Service
- ESLint & Prettier
- Playwright Test Explorer
- GitLens & SonarLint
- GitHub Copilot (if licensed)

---

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

---

## Port Forwarding

| Port | Service |
|------|---------|
| 4200 | Angular dev server |
| 8080 | Spring Boot backend |
| 9323 | Playwright report server |
| 35729 | LiveReload |

---

## Environment Variables

### NVD API Key (Optional but Recommended)

For faster OWASP Dependency-Check scans:

1. Get a free API key from [NVD](https://nvd.nist.gov/developers/request-an-api-key)
2. Create `backend/.env`:
   ```
   NVD_API_KEY=your-api-key-here
   ```

---

## Troubleshooting

### Image not being pulled (building locally instead)

**Cause**: Not authenticated to GitLab Container Registry

**Solution**:
```bash
docker login registry.gitlab.com
```

### Container fails to start

- Ensure Docker Desktop is running
- Check Docker has enough resources (6GB RAM, 32GB disk recommended)
- Try removing cached volumes:
  ```bash
  docker volume rm wordle-kata-maven-cache wordle-kata-pnpm-cache wordle-kata-playwright-cache
  ```

### Out of memory errors

Increase Docker memory limit in Docker Desktop settings to 6GB+.

### Permission errors

Named volumes may have stale permissions. Remove and recreate:
```bash
docker volume rm wordle-kata-maven-cache wordle-kata-pnpm-cache
```

---

## For Maintainers: Building & Pushing the Image

### Automatic (CI/CD)

The GitLab CI pipeline automatically builds and pushes when:
- Files in `.devcontainer/` change on `main` branch
- Manually triggered from GitLab UI

### Manual Build & Push

```bash
# Login with write access
docker login registry.gitlab.com

# Build and push
.devcontainer/build-and-push.sh

# Or with a specific tag
.devcontainer/build-and-push.sh v1.0.0
```

---

## Pre-built Image

```
registry.gitlab.com/simplificationofficers/wordle-kata/devcontainer:latest
```

Team members pull this image automatically - no local build required!

---

## Files in This Directory

| File | Purpose |
|------|---------|
| `devcontainer.json` | Main configuration (features, extensions, settings) |
| `Dockerfile` | Container image definition |
| `docker-compose.yml` | Service configuration and volumes |
| `post-create.sh` | Runs once after container creation |
| `post-start.sh` | Runs every time container starts |
| `build-and-push.sh` | Script to build and push image to registry |
