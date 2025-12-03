# Wordle Coding Kata 🎯

**Challenge:** Transform a "Hello World" app into a fully functional Wordle game while maintaining **Hexagonal Architecture** and **100% test coverage**!

## What Is This?

This is a **coding kata** designed for teams practicing:
- 🔴🟢🔵 **Test-Driven Development** (TDD Red-Green-Refactor)
- 🏛️ **Hexagonal Architecture** (Ports & Adapters)
- 👥 **Mob/Ensemble Programming** (collaborative coding)
- ✨ **Clean Code Principles** (SOLID, DRY, readable code)
- 🤖 **AI-Assisted Development** (leverage AI tools while maintaining quality!)

## The Challenge

You start with a fully functional "Hello World" application with **100% test coverage** and clean architecture. Your mission: **replace it with a Wordle game** that meets the exact specifications in the PRD—while keeping everything working, tested, and beautiful along the way.

**What You Get:**
- ✅ **Backend**: Java 21 + Spring Boot (Hexagonal Architecture)
- ✅ **Frontend**: Angular 21 + Nx + PrimeNG (standalone components + signals)
- ✅ **100% Code Coverage**: Maintained on both projects
- ✅ **Clean Architecture**: Enforced by ArchUnit tests
- ✅ **Production-Ready Setup**: Nx build caching, library-based organization
- ✅ **Working Application**: Deployable at every step

## 📋 The Specifications (Non-Negotiable!)

Your Wordle implementation **must** follow the complete specification in:
- **[docs/wordle-prd.md](./docs/wordle-prd.md)** - Product Requirements Document with detailed game rules, functional requirements, and acceptance criteria

**Scope for this kata:**
- ✅ Milestones 1-5 (Stories 001-022) covering the full core Wordle experience
- 🎁 Post-milestone enhancements (advanced backlog) are optional for ambitious teams

## 🗺️ Suggested Implementation Path

We've broken down the PRD into **22 small, testable user stories** organized into 5 milestones:
- **[docs/wordle-stories.md](./docs/wordle-stories.md)** - User stories with Specification by Example

Each story is designed for:
- Short TDD cycle (Red-Green-Refactor)
- Independent implementation (INVEST principles)
- Immediate user value and feedback opportunity

**You don't have to follow these stories exactly**, but they provide a solid incremental path from "Hello World" to "Wordle"!

## 🚀 How to Approach This Kata

**For Mob/Ensemble Teams:**
1. **Start small**: Pick Story 001 or create your own first step
2. **Red-Green-Refactor**: Write a failing test, make it pass, clean up
3. **Keep it green**: Never break the build, coverage, or quality checks
4. **Rotate frequently**: Switch drivers every 5-10 minutes
5. **Collaborate**: Discuss, debate, learn together!

**Duration:** Half-day to multiple days (go at your own pace, as far as you can!)

**🤖 AI Tools Welcome!**
Use AI assistants (GitHub Copilot, JetBrains AI, Claude Code, ChatGPT, etc.) as much as you want! But remember:
- **You** are responsible for code quality
- **You** must understand what the AI generates
- **You** must maintain tests, coverage, and architecture
- AI is a **tool**, not a replacement for thinking!

Think of AI as an extra mob member with infinite knowledge but no judgement—use it wisely! ✨

## Quick Start

**Only 2 steps to get started:**

### 1. Install Prerequisites (one-time)

<details open>
<summary><strong>macOS (Homebrew)</strong></summary>

```bash
brew install openjdk@21 maven node@20
npm install -g pnpm
```
</details>

<details>
<summary><strong>Ubuntu/Debian</strong></summary>

```bash
sudo apt install openjdk-21-jdk maven
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install nodejs
npm install -g pnpm
```
</details>

<details>
<summary><strong>Fedora/RHEL</strong></summary>

```bash
sudo dnf install java-21-openjdk-devel maven nodejs
npm install -g pnpm
```
</details>

<details>
<summary><strong>Windows (winget)</strong></summary>

```powershell
winget install EclipseAdoptium.Temurin.21.JDK Apache.Maven OpenJS.NodeJS.LTS
npm install -g pnpm
```
</details>

<details>
<summary><strong>Windows (Scoop)</strong></summary>

```powershell
scoop install temurin21-jdk maven nodejs-lts
npm install -g pnpm
```
</details>

### 2. Clone and Verify

```bash
git clone <repository-url>
cd wordle-kata
./quality-check.sh
```

**That's it!** The script automatically:
- Validates all prerequisites (shows install commands if missing)
- Installs pnpm if npm exists but pnpm doesn't
- Installs all project dependencies (frontend, e2e-tests, backend)
- Installs security tools (gitleaks, semgrep)
- Runs all 14 quality checks

**All checks must pass before you start coding!**

## Development

### Start the Application

```bash
# Terminal 1: Backend (http://localhost:8080)
cd backend && mvn -Prun

# Terminal 2: Frontend (http://localhost:4200)
cd frontend && pnpm start
```

Open `http://localhost:4200` in your browser.

**Note:** Use `pnpm` for all frontend/e2e commands (not `npm`).

## 📦 Prerequisites Reference

| Tool | Version | Purpose |
|------|---------|---------|
| Java | 21 | Backend runtime (see `.java-version`) |
| Maven | 3.9+ | Backend build tool |
| Node.js | 20+ | Frontend runtime (see `.nvmrc`) |
| pnpm | latest | Frontend package manager |
| Git | any | Version control |

**Recommended Knowledge:**
- Familiarity with TDD principles
- Basic understanding of Hexagonal Architecture (or willingness to learn!)
- Experience with Java/Spring Boot and TypeScript/Angular (or strong fundamentals)
- Knowledge of how Wordle works (play a few games at [nytimes.com/games/wordle](https://www.nytimes.com/games/wordle))

## Configuration

Both backend and frontend are **loosely coupled** via environment-based configuration:

### Backend Configuration
- **Environment Variable**: `CORS_ALLOWED_ORIGINS` (default: `http://localhost:4200`)
- **Production Example**: `export CORS_ALLOWED_ORIGINS=https://myapp.com,https://www.myapp.com`
- **Details**: See [backend/README.md](./backend/README.md#cors-configuration)

### Frontend Configuration
- **Environment Files**: `apps/hello-world-frontend/src/environments/environment.ts` (dev) and `environment.prod.ts` (prod)
- **Development**: Points to `http://localhost:8080/api`
- **Production**: Uses relative URL `/api` (same domain as frontend)
- **Details**: See [frontend/README.md](./frontend/README.md#environment-configuration)

## 🏛️ Architecture (Maintain This!)

### Backend (Hexagonal/Ports & Adapters)
Your backend follows **Hexagonal Architecture** with strict layer separation. As you build Wordle:
- **Keep the layers clean**: Domain → Application → Adapters
- **Respect the boundaries**: ArchUnit tests will catch violations!
- **Use Vavr's Either pattern**: For elegant error handling
- **Test everything**: Behavior tests + ArchUnit rules

**Current state:**
- **Tech**: Java 21, Spring Boot 3.4.1, Vavr (Either pattern)
- **Testing**: JUnit 5 + AssertJ + ArchUnit (12 architecture rules enforced)
- **Coverage**: JaCoCo 0.8.12 - **100%** (21 tests: 9 behavior + 12 ArchUnit)

### Frontend (Modern Angular + Nx)
Your frontend uses **Angular 21** with modern patterns and **Nx workspace**. As you build the Wordle UI:
- **Standalone components**: No NgModules needed
- **Signals for state**: Reactive, performant state management
- **Library-based organization**: Nx-style apps/ + libs/ structure with path aliases
- **PrimeNG UI library**: 90+ production-ready components for rapid development
- **Component tests with Cypress**: Real browser testing

**Current state:**
- **Tech**: Angular 21, TypeScript 5.9.3, Nx 22.1.1, PrimeNG 20.3.0, Cypress 15.7.0
- **Code Quality**: ESLint 9.39.1 + Prettier 3.6.2 (auto-enforced)
- **Coverage**: Custom Istanbul instrumentation - **100%** (10 Cypress component tests)

## 💯 Code Coverage (Keep It at 100%!)

**Starting point** (Hello World implementation):

| Project | Instructions | Branches | Lines | Methods/Functions | Tests |
|---------|--------------|----------|-------|-------------------|-------|
| **Backend** | 100% (137/137) | 100% (6/6) | 100% (25/25) | 100% (11/11) | 21 |
| **Frontend** | 100% (50/50) | 100% (0/0) | 100% (44/44) | 100% (11/11) | 10 |

**Your challenge:** Keep it at 100% as you replace Hello World with Wordle! 🎯

Every new feature needs tests. Every refactoring must keep tests green. No excuses, no shortcuts—this is the kata way!

## 🧪 Running Tests

### Unit & Component Tests (Run These Often!)

```bash
# Backend (JUnit + ArchUnit) - with coverage report
cd backend && mvn test
open target/site/jacoco/index.html

# Frontend (Cypress Component Tests) - with coverage report
cd frontend && pnpm test:coverage
open coverage/index.html
```

**Pro tip:** Run tests frequently! After every small change, make sure everything is still green. That's the TDD heartbeat! ❤️

### E2E Tests (Run Before Commits)

We have **Playwright BDD tests** that verify full-stack integration (no mocking).

**⚡ Services start automatically** - No manual setup required!

```bash
# Run E2E tests (headless) - services start automatically!
cd e2e-tests && pnpm test:e2e

# Run E2E tests (watch browser)
cd e2e-tests && pnpm test:e2e:headed

# Interactive UI mode
cd e2e-tests && pnpm test:e2e:ui

# Cleanup orphaned processes (if tests crash)
cd e2e-tests && pnpm cleanup
```

## 📚 Documentation

**Kata Specifications:**
- **[docs/wordle-prd.md](./docs/wordle-prd.md)** - Complete Product Requirements Document (your north star!)
- **[docs/wordle-stories.md](./docs/wordle-stories.md)** - 22 user stories with Specification by Example

**Technical Details:**
- **[Backend README](./backend/README.md)** - Architecture, API endpoints, testing, development guidelines
- **[Frontend README](./frontend/README.md)** - Components, testing strategy, code quality, development guidelines
- **[Frontend Coverage Setup](./frontend/COVERAGE.md)** - Manual Istanbul instrumentation details
- **[E2E Tests Guide](./e2e-tests/README.md)** - Playwright BDD setup, running E2E tests, best practices

**Infrabel Specific**
- **[UPM Train Planning vs Wordle Backend](./backend/upmng-service-train-planning-vs-backend.md)** - The main differences between working at an Infrabel backend vs this Wordle Kata
- **[UPM Frontend vs Wordle Frontend](./frontend/upm-client-vs-frontend.md)** - The main differences between working at an Infrabel frontend vs this Wordle Kata

---

## 🎉 Ready to Start?

**Remember:**
- ✅ Start with the "Hello World" app (it works perfectly!)
- ✅ Pick your first story (or create your own tiny first step)
- ✅ Write a test (RED), make it pass (GREEN), clean it up (REFACTOR)
- ✅ Keep the app working and coverage at 100%
- ✅ Run quality checks before every commit
- ✅ Use AI tools to help, but understand everything you commit
- ✅ Collaborate, learn, and have fun!

**This is not a race—it's a learning journey.** Some teams will complete Milestone 1 in half a day. Others will spend multiple days perfecting all 22 stories. Both are winning! 🏆

The goal is **not** to finish quickly. The goal is to:
- Practice TDD in a realistic scenario
- Experience Hexagonal Architecture in action
- Collaborate effectively as a team
- Write clean, maintainable, well-tested code
- Learn from each other (and from AI!)

**Now go build something awesome!** 🚀

---

## 📜 License

This is a demonstration project for educational purposes. Use it, share it, learn from it!

**Happy Coding!** 💻✨
