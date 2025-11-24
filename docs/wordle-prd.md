# Wordle Application - Product Requirements Document

**Version:** 1.0
**Last Updated:** November 20, 2025
**Status:** Draft
**Owner:** Jurgen De Smet

---

## Executive Summary

This document outlines the requirements for building a web-based Wordle game application. The application will serve as both a playable word-guessing game and a coding kata demonstrating modern software architecture, test-driven development, and clean code principles.

**Key Highlights:**
- Full-stack web application (Angular 21 + Spring Boot)
- Hexagonal architecture with 100% code coverage
- Phased development approach (MVP → Core → Extended)
- Educational kata for demonstrating best practices
- Production-ready quality standards

---

## 1. Goals and Objectives

### Primary Goals
1. **Deliver a fully functional Wordle game** that matches the core gameplay experience
2. **Demonstrate architectural excellence** through Hexagonal Architecture and clean code
3. **Maintain 100% code coverage** with behavior-focused tests
4. **Provide a learning platform** for TDD and modern development practices

### Success Criteria
- [ ] Users can play a complete Wordle game with standard rules
- [ ] All business logic has 100% test coverage
- [ ] Architecture rules enforced by ArchUnit tests
- [ ] Application follows SOLID principles and clean code practices
- [ ] Game is playable on modern browsers (Chrome, Firefox, Safari, Edge)

---

## 2. User Personas

### Primary Persona: Casual Player
- **Name:** Sarah
- **Age:** 28
- **Tech Savviness:** Medium
- **Goals:** Quick daily mental exercise, compete with friends
- **Pain Points:** Wants simple, fast gameplay without distractions

### Secondary Persona: Competitive Player
- **Name:** Mike
- **Age:** 35
- **Tech Savviness:** High
- **Goals:** Track statistics, improve strategy, compete on leaderboards
- **Pain Points:** Wants detailed stats, hard mode challenge

### Tertiary Persona: Developer/Learner
- **Name:** Alex
- **Age:** 24
- **Tech Savviness:** High (Developer)
- **Goals:** Learn architecture patterns, study clean code implementation
- **Pain Points:** Needs well-documented, testable, maintainable code

---

## 3. Game Rules and Mechanics

### Core Game Rules
1. **Objective:** Guess a secret 5-letter English word in 6 attempts or fewer
2. **Feedback System:** After each guess, receive color-coded feedback:
   - 🟩 **Green:** Letter is correct and in the correct position
   - 🟨 **Yellow:** Letter is in the word but in the wrong position
   - ⬜ **Gray:** Letter is not in the word
3. **Valid Guesses:** Only valid 5-letter English words accepted
4. **Win Condition:** Guess the exact word
5. **Loss Condition:** Fail to guess after 6 attempts

### Game Constraints
- Exactly 5 letters per word
- Only alphabetic characters (A-Z)
- Case-insensitive input
- One puzzle per session (Phase 1-2)
- One puzzle per day (Phase 3 - Daily Challenge mode)

### Special Rules (Hard Mode - Phase 3)
- Must use green letters in same position in subsequent guesses
- Must use yellow letters in subsequent guesses
- Cannot ignore revealed information

---

## 4. Functional Requirements

### 4.1 Milestone 1: Basic Game (Stories 001-006)

#### M1.1 (Story 001) Game Initialization
- **Given** a user opens the application
- **When** the game loads
- **Then** set a hardcoded 5-letter target word (e.g., "CRANE")
- **And** ensure the game is ready to accept guesses immediately

#### M1.2 (Stories 001-003) Accept Guess Input
- **Given** the game is active
- **When** the user types in the input field
- **Then** accept alphabetic characters only, ignoring other keystrokes
- **And** limit input to 5 characters maximum, silently truncating excess input

#### M1.3 (Story 004) Submission Guardrails
- **Given** the user interacts with the submit action
- **When** the guess length is not 5 characters
- **Then** show the error "Word must be exactly 5 letters"
- **And** disable submission via both button and Enter key until 5 letters are present

#### M1.4 (Stories 005-006) Result Feedback
- **Given** a valid guess is submitted
- **When** the guess is evaluated against the target word
- **Then** display "You won!" for exact matches and "Incorrect. Try again." otherwise
- **And** clear the input for the next attempt when incorrect

#### M1.5 (Story 006) Reveal Target Word
- **Given** the game has ended (win or 6 failed attempts)
- **When** the final result is shown
- **Then** reveal the target word to the user

**Milestone 1 Success Criteria:**
- ✅ Players can enter, validate, and submit 5-letter guesses
- ✅ Immediate win/try-again feedback is visible
- ✅ Game reveals the target word when play stops
- ✅ 100% test coverage on core logic

---

### 4.2 Milestone 2: Game Progress (Stories 007-010)

#### M2.1 (Story 007) Guess Counter
- **Given** the game has started
- **When** the player submits each valid guess
- **Then** update the counter (e.g., "Guess 3/6") so progress is always visible

#### M2.2 (Story 008) Attempt Limit Enforcement
- **Given** the player has reached six guesses or has already won
- **When** the UI renders
- **Then** disable the input field and submit button
- **And** prevent additional keyboard input from altering the current row

#### M2.3 (Stories 009-010) Win/Loss Messaging
- **Given** the player submits a guess
- **When** all letters are correct
- **Then** display celebratory copy that varies by attempt (e.g., "Genius!", "Magnificent!", "Great!")
- **Else When** six incorrect guesses occur
- **Then** display "Game Over! The word was: [WORD]" while revealing the word and locking the UI

**Milestone 2 Success Criteria:**
- ✅ Guess counter mirrors actual attempts
- ✅ No guesses allowed after six tries or a win
- ✅ Distinct win/loss messaging matches the stories

---

### 4.3 Milestone 3: Letter Feedback (Stories 011-015)

#### M3.1 (Stories 011-014) Color-Coded Feedback
- **Given** a valid guess is submitted
- **When** evaluating each letter left-to-right
- **Then** assign colors with green taking priority over yellow and gray for absent letters
- **And** handle duplicates by only coloring as many instances as exist in the target word

#### M3.2 (Story 015) Guess History Display
- **Given** at least one guess has been submitted
- **When** the game board renders
- **Then** list previous guesses in order, showing per-letter colors that match the evaluation rules

**Milestone 3 Success Criteria:**
- ✅ Letter-by-letter colors match official Wordle behavior, including duplicates
- ✅ Guess history persists visually for the full session
- ✅ Keyboard/input hints stay synchronized with the evaluations

---

### 4.4 Milestone 4: Visual Grid (Stories 016-019)

#### M4.1 (Story 016) Initial Grid Layout
- **Given** the game loads
- **When** the UI renders
- **Then** display a 6x5 empty grid with neutral borders to signal six attempts

#### M4.2 (Story 017) Live Row Preview
- **Given** the player is typing the current guess
- **When** characters are entered or deleted
- **Then** mirror the text in the active grid row in real time, highlighting the active row visually

#### M4.3 (Story 018) Row Locking with Feedback
- **Given** the player submits a guess
- **When** the evaluation completes
- **Then** color the just-submitted row, lock it from further edits, and advance the active row indicator

#### M4.4 (Story 019) Grid Finalization
- **Given** the game has ended
- **When** rendering the board
- **Then** leave all rows read-only and remove the active row indicator to make the end state obvious

**Milestone 4 Success Criteria:**
- ✅ Grid is present from the start and previews live typing
- ✅ Submitted rows lock with the correct colors
- ✅ End-state grid clearly communicates win/loss

---

### 4.5 Milestone 5: Word Validation (Stories 020-022)

#### M5.1 (Story 020) Dictionary Validation
- **Given** the player submits a 5-letter guess
- **When** validation occurs
- **Then** check the guess against the curated dictionary/word list
- **And** reject words that are not in the list

#### M5.2 (Story 021) Error Experience
- **Given** a guess fails dictionary validation
- **When** the error is displayed
- **Then** show "Not in word list" (or equivalent), keep focus on the input, and dismiss the error once the player starts typing again

#### M5.3 (Story 022) Case Normalization
- **Given** the player types letters in any case
- **When** the guess is processed
- **Then** normalize to a single case (uppercase recommended) for validation and display so comparisons remain case-insensitive

**Milestone 5 Success Criteria:**
- ✅ Only real words enter the evaluation logic
- ✅ Errors are actionable and disappear on new input
- ✅ Case handling is consistent between validation, grid, and keyboard

---

### 4.6 Post-Milestone Enhancements (Advanced Growth Path)

#### FR3.1: Random Word Selection
- **Given** a new game starts
- **When** the target word is selected
- **Then** randomly choose from a curated word list
- **And** ensure word is valid 5-letter English word
- **And** avoid repeating recent words (optional)

**Acceptance Criteria:**
- Word list contains 2,000+ valid 5-letter words
- Words are common English vocabulary
- No proper nouns, abbreviations, or obscure words
- Randomization is fair (uniform distribution)

#### FR3.2: Score Tracking and Statistics
- **Given** a user plays multiple games
- **When** games are completed
- **Then** track the following statistics:
  - Games played
  - Games won
  - Win percentage
  - Current streak
  - Max streak
  - Guess distribution (1-6 guesses)

**Acceptance Criteria:**
- Statistics persist across sessions (localStorage for MVP)
- Statistics reset option available
- Display statistics in dedicated view
- Guess distribution shown as histogram

#### FR3.3: Multiple Game Modes
**4-Letter Mode:**
- Target word is 4 letters
- Maximum 5 guesses
- Separate statistics

**6-Letter Mode:**
- Target word is 6 letters
- Maximum 7 guesses
- Separate statistics

**Acceptance Criteria:**
- Mode selection before game start
- Separate word lists per mode
- Clear visual distinction between modes

#### FR3.4: Hard Mode
- **Given** hard mode is enabled
- **When** a user makes a guess
- **Then** enforce the following rules:
  - Must use all revealed green letters in same positions
  - Must use all revealed yellow letters (in different positions)
  - Reject guesses that violate these rules
  - Show specific error message explaining violation

**Acceptance Criteria:**
- Toggle hard mode on/off before game starts
- Cannot change mode mid-game
- Clear indication that hard mode is active
- Helpful error messages when rules violated

#### FR3.5: Daily Challenge
- **Given** a new calendar day
- **When** the user starts a game
- **Then** all users worldwide get the same target word
- **And** word changes at midnight UTC
- **And** users can only play once per day
- **And** previous day's word is archived

**Acceptance Criteria:**
- Seed-based deterministic word selection
- Same word for all users on same day
- Prevents multiple attempts on same puzzle
- Archive of past daily words available

#### FR3.6: Multiplayer / Competitive Mode
**Race Mode:**
- Two players compete to guess the same word
- First to guess correctly wins
- Display opponent's progress in real-time

**Head-to-Head:**
- Players alternate choosing words for each other
- Best of 3 rounds
- Track win/loss record

**Acceptance Criteria:**
- Lobby system for matchmaking
- Real-time synchronization
- Handle disconnections gracefully
- Display match history

#### FR3.7: Hint System
**Hint Types:**
1. **Vowel Hint:** Reveal if a vowel (A,E,I,O,U) is in the word
2. **Letter Frequency Hint:** Reveal if word contains common/rare letters
3. **Category Hint:** Reveal word category (animal, food, place, etc.)

**Constraints:**
- Limited hints per game (e.g., 1 hint)
- Using hint affects scoring/statistics
- Optional feature (can be disabled)

**Acceptance Criteria:**
- Clear UI for requesting hints
- Hints are helpful but not game-breaking
- Statistics track hint usage

#### FR3.8: Timer / Speed Mode
- **Given** speed mode is enabled
- **When** the game starts
- **Then** start a countdown timer (e.g., 60 seconds)
- **And** end game when timer expires
- **And** track completion time for completed games

**Acceptance Criteria:**
- Configurable time limits (30s, 60s, 90s)
- Visual timer display
- Leaderboard for fastest completions
- Separate statistics for timed games

#### FR3.9: User Accounts and Leaderboards
**User Accounts:**
- Registration with email/username
- Secure authentication (OAuth or JWT)
- Profile management
- Cross-device synchronization

**Leaderboards:**
- Global leaderboard (by win streak, win %, avg guesses)
- Daily challenge leaderboard
- Speed mode leaderboard
- Friends leaderboard

**Acceptance Criteria:**
- Secure password storage (hashed)
- Email verification
- Password reset functionality
- Privacy controls for statistics

#### FR3.10: Share Results
- **Given** a user completes a game
- **When** the user clicks "Share Results"
- **Then** generate a shareable emoji grid showing:
  - Wordle puzzle number (if daily challenge)
  - Number of guesses (X/6)
  - Emoji representation of guess pattern (🟩🟨⬜)
  - No spoilers (no actual letters)

**Example Output:**
```
Wordle 234 4/6

⬜⬜🟨⬜🟩
⬜🟩⬜⬜🟩
🟩🟩⬜🟩🟩
🟩🟩🟩🟩🟩
```

**Acceptance Criteria:**
- Copy to clipboard functionality
- Direct share to social media (optional)
- No spoilers in shared content
- Consistent format with original Wordle

#### FR3.11: Word Categories
**Category Types:**
- Animals (TIGER, WHALE, etc.)
- Foods (BREAD, APPLE, etc.)
- Places (PARIS, BEACH, etc.)
- General vocabulary (default)

**Acceptance Criteria:**
- Category selection before game
- Curated word lists per category
- Minimum 500 words per category
- Clear indication of active category

---

### 4.7 Growth Path Alignment

To keep the Product Requirements Document synchronized with the incremental growth path captured in `docs/wordle-stories.md`, each milestone above maps directly to user-facing stories:

| Milestone (Stories) | Scope Summary | Related PRD Phase / Feature IDs |
|---------------------|---------------|----------------------------------|
| **Milestone 1: Basic Game** (Stories 001-006) | Input field, alphabet-only enforcement, 5-character limit, guess submission, win/loss messaging | Section 4.1 (M1.1-M1.5) |
| **Milestone 2: Game Progress** (Stories 007-010) | Guess counter, attempt limit, disable after win/loss, tailored win/loss copy | Section 4.2 (M2.1-M2.3) |
| **Milestone 3: Letter Feedback** (Stories 011-015) | Letter-level feedback, duplicate handling, guess history list | Section 4.3 (M3.1-M3.2) |
| **Milestone 4: Visual Grid** (Stories 016-019) | Static 6x5 grid, live typing preview, per-row color lock, read-only end state | Section 4.4 (M4.1-M4.4) & UI requirements in Section 7 |
| **Milestone 5: Word Validation** (Stories 020-022) | Dictionary validation, word-list error UX, case normalization | Section 4.5 (M5.1-M5.3) |

All future milestones (beyond Story 022) remain captured in the post-milestone enhancements list (Section 4.6) and should only be tackled after Milestones 1-5 are completed in order.

## 5. Non-Functional Requirements

### 5.1 Performance
- **NFR-P1:** Game UI must respond to user input within 100ms
- **NFR-P2:** Word validation must complete within 200ms
- **NFR-P3:** Page load time under 2 seconds on 3G connection
- **NFR-P4:** Support 10,000+ concurrent users (Phase 3)

### 5.2 Usability
- **NFR-U1:** Game must be playable without tutorial for experienced Wordle players
- **NFR-U2:** Keyboard navigation fully supported
- **NFR-U3:** Responsive design (mobile, tablet, desktop)

### 5.3 Maintainability
- **NFR-M1:** 100% code coverage on business logic
- **NFR-M2:** All tests are behavior-focused, not implementation-focused
- **NFR-M3:** Hexagonal Architecture enforced by ArchUnit tests
- **NFR-M4:** Code follows Clean Code principles (max 300 lines/file)
- **NFR-M5:** Comprehensive documentation for all public APIs

### 5.4 Testability
- **NFR-T1:** All features testable in isolation
- **NFR-T2:** Test execution time under 30 seconds (unit tests)
- **NFR-T3:** Integration tests under 2 minutes
- **NFR-T4:** E2E tests under 5 minutes
- **NFR-T5:** TDD approach for all new features

---

## 6. Technical Architecture

### 6.1 Architecture Pattern

**Hexagonal Architecture (Ports & Adapters)**

```
┌─────────────────────────────────────────────────┐
│                   Adapters                      │
│  ┌──────────────┐              ┌─────────────┐ │
│  │ REST API     │              │  Angular    │ │
│  │ (Spring)     │              │  Frontend   │ │
│  └──────────────┘              └─────────────┘ │
│         │                             │         │
│         ▼                             ▼         │
│  ┌──────────────────────────────────────────┐  │
│  │           Application Layer              │  │
│  │  ┌────────────────────────────────────┐  │  │
│  │  │   Command Processors (Ports)       │  │  │
│  │  │  - ValidateGuessProcessor          │  │  │
│  │  │  - SubmitGuessProcessor            │  │  │
│  │  │  - StartGameProcessor              │  │  │
│  │  │  - GetGameStateProcessor           │  │  │
│  │  └────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────┘  │
│                       │                         │
│                       ▼                         │
│  ┌──────────────────────────────────────────┐  │
│  │           Domain Layer                   │  │
│  │  ┌────────────────────────────────────┐  │  │
│  │  │   Value Objects                    │  │  │
│  │  │  - Word                            │  │  │
│  │  │  - Guess                           │  │  │
│  │  │  - LetterResult (Green/Yellow/Gray│  │  │
│  │  │  - GameState                       │  │  │
│  │  │  - GuessResult                     │  │  │
│  │  └────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────┘  │
│                       │                         │
│                       ▼                         │
│  ┌──────────────────────────────────────────┐  │
│  │      Infrastructure (Optional)           │  │
│  │  - WordRepository                        │  │
│  │  - StatisticsRepository                  │  │
│  │  - DictionaryService                     │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### 6.2 Technology Stack

**Backend:**
- **Language:** Java 21
- **Framework:** Spring Boot 3.2.0
- **Error Handling:** Vavr Either pattern
- **Build Tool:** Maven 3.9+
- **Testing:** JUnit 5, AssertJ, ArchUnit
- **Code Coverage:** JaCoCo 0.8.12 (100% target)

**Frontend:**
- **Framework:** Angular 21
- **Language:** TypeScript 5.9.3
- **State Management:** Angular Signals
- **Testing:** Cypress 15.7.0 (component testing)
- **Code Quality:** ESLint 9.39.1, Prettier 3.6.2
- **Code Coverage:** Custom Istanbul instrumentation (100% target)

**Infrastructure (Phase 3):**
- **Database:** PostgreSQL or MongoDB (for user accounts, statistics)
- **Caching:** Redis (for daily challenge, leaderboards)
- **Authentication:** JWT or OAuth 2.0
- **Deployment:** Docker containers, Kubernetes (optional)

---

## 7. User Interface / User Experience

### 7.1 Core UI Components

**Game Board (6x5 Grid):**
```
┌───┬───┬───┬───┬───┐
│ C │ R │ A │ N │ E │  ← Guess 1 (submitted)
├───┼───┼───┼───┼───┤
│ S │ L │ A │ T │ E │  ← Guess 2 (submitted)
├───┼───┼───┼───┼───┤
│ B │ L │ A │ Z │ E │  ← Guess 3 (submitted)
├───┼───┼───┼───┼───┤
│   │   │   │   │   │  ← Guess 4 (empty)
├───┼───┼───┼───┼───┤
│   │   │   │   │   │  ← Guess 5 (empty)
├───┼───┼───┼───┼───┤
│   │   │   │   │   │  ← Guess 6 (empty)
└───┴───┴───┴───┴───┘
```

**Keyboard Component:**
- On-screen keyboard showing letter states
- Gray out used letters not in word
- Yellow highlight letters in word (wrong position)
- Green highlight letters in correct position

**Header:**
- Game title/logo
- Menu button (settings, stats, help)
- Streak indicator (Phase 3)

**Input Field:**
- Text input for current guess
- Auto-focus on load
- Enter key to submit
- Delete/Backspace support

**Feedback Panel:**
- Win message: "Genius!" (1 guess), "Magnificent!" (2), "Great!" (3-4), "Nice!" (5-6)
- Loss message: "Better luck next time! The word was: [WORD]"
- Error messages: "Not in word list", "Not enough letters", "Too many attempts"

### 7.2 Responsive Design

**Mobile (320px - 767px):**
- Single column layout
- Smaller tile size (48px x 48px)
- On-screen keyboard always visible
- Full-screen game board

**Tablet (768px - 1023px):**
- Centered layout with padding
- Medium tile size (60px x 60px)
- On-screen keyboard optional
- Side panels for stats (Phase 3)

**Desktop (1024px+):**
- Centered layout, max-width 500px
- Large tile size (72px x 72px)
- On-screen keyboard optional
- Side panels for leaderboard, stats (Phase 3)

---

## 8. Development Roadmap

### Phase 1: MVP (Week 1)

**Deliverables:**
- [ ] Hardcoded target word ("CRANE")
- [ ] Text input for guesses
- [ ] Basic validation (5 letters, alphabetic)
- [ ] Win/loss detection
- [ ] Display target word after game ends
- [ ] 100% test coverage on all logic
- [ ] All tests passing
- [ ] Milestone coverage: Stories 001-006 (Basic Game) and 007-010 (Game Progress) satisfied sequentially

**Definition of Done:**
- User can play one complete game
- All acceptance criteria met for FR1.1-FR1.5
- Tests cover all business logic
- Documentation updated
- Milestones 1 & 2 validated against `docs/wordle-stories.md`

---

### Phase 2: Core Gameplay (Week 1-2)

**Deliverables:**
- [ ] Color-coded feedback (green/yellow/gray)
- [ ] 6-guess limit enforcement
- [ ] Word validation against dictionary
- [ ] Win/loss detection
- [ ] Visual grid (6x5 tiles)
- [ ] Letter status tracking
- [ ] Game state management
- [ ] 100% test coverage maintained
- [ ] Milestone coverage: Stories 011-022 (Letter Feedback, Visual Grid, Word Validation)

**Definition of Done:**
- Full Wordle game experience
- All acceptance criteria met for FR2.1-FR2.5
- UI matches Wordle aesthetic
- All tests passing
- Milestones 3-5 validated against `docs/wordle-stories.md`

---

### Phase 3: Extended Features (Ongoing)
**Modular feature additions - prioritize based on value**

#### Sprint 1: Random Words & Stats (Week 3)
- [ ] Random word selection from word list (FR3.1)
- [ ] Statistics tracking (FR3.2)
- [ ] Statistics display UI
- [ ] Word list curation (2,000+ words)

#### Sprint 2: Game Modes (Week 4)
- [ ] Hard mode implementation (FR3.4)
- [ ] 4-letter and 6-letter modes (FR3.3)
- [ ] Mode selection UI
- [ ] Separate statistics per mode

#### Sprint 3: Daily Challenge (Week 5)
- [ ] Daily word selection (FR3.5)
- [ ] Seed-based deterministic words
- [ ] Prevent multiple daily attempts
- [ ] Daily statistics tracking
- [ ] Archive past dailies

#### Sprint 4: Social Features (Week 6-7)
- [ ] Share results (FR3.10)
- [ ] Emoji grid generation
- [ ] Copy to clipboard
- [ ] Social media integration

#### Sprint 5: User Accounts (Week 8-10)
- [ ] User registration/login (FR3.9)
- [ ] Profile management
- [ ] Cross-device sync
- [ ] Password reset
- [ ] Email verification

#### Sprint 6: Leaderboards (Week 11-12)
- [ ] Global leaderboard (FR3.9)
- [ ] Daily challenge leaderboard
- [ ] Friends leaderboard
- [ ] Score calculation algorithm

#### Sprint 7: Advanced Features (Week 13+)
- [ ] Multiplayer mode (FR3.6)
- [ ] Hint system (FR3.7)
- [ ] Speed mode (FR3.8)
- [ ] Word categories (FR3.11)

---

## 9. Out of Scope

The following features are explicitly **OUT OF SCOPE** for initial releases:

### Not in MVP or Phase 2:
- ❌ User accounts and authentication
- ❌ Multiplayer or competitive modes
- ❌ Leaderboards
- ❌ Daily challenge
- ❌ Statistics and score tracking
- ❌ Word categories
- ❌ Hint systems
- ❌ Timer/speed mode
- ❌ Multiple word lengths (4, 6, 7 letters)
- ❌ Hard mode

### Not Planned (Future Consideration):
- ❌ Native mobile apps (iOS/Android)
- ❌ Offline mode / Progressive Web App
- ❌ Internationalization (non-English languages)
- ❌ Voice input
- ❌ Custom word creation by users
- ❌ Puzzle editor/creator mode
- ❌ Team/collaborative mode
- ❌ Tournament system
- ❌ Virtual currency or monetization
- ❌ Advertisements

---

## 10. Assumptions and Dependencies

### 10.1 Assumptions

1. **Target Audience:** English-speaking users familiar with web browsers
2. **Word List Availability:** Curated word lists are available (e.g., from open-source projects)
3. **Dictionary API:** Free dictionary API available or word list can be bundled
4. **Browser Support:** Users have modern browsers (ES6+ support)
5. **Network:** Users have internet connection (no offline support in Phase 1-2)
6. **Screen Size:** Minimum 320px width (standard smartphone)
7. **Input Method:** Keyboard or on-screen keyboard available
8. **Development Time:** Phased approach allows for incremental delivery
9. **Testing:** TDD approach followed for all features
10. **Architecture:** Hexagonal architecture maintained throughout

### 10.2 Dependencies

**External Services:**
- Dictionary API or word list (e.g., GitHub word lists, Datamuse API)
- Random word generation (could be local or API)
- Email service (Phase 3 - for user accounts, SendGrid/AWS SES)
- Authentication service (Phase 3 - OAuth providers or custom JWT)

**Infrastructure:**
- Web hosting (AWS, Azure, GCP, Netlify, Vercel)
- Database (Phase 3 - PostgreSQL, MongoDB)
- Caching (Phase 3 - Redis)
- CDN (Phase 3 - CloudFlare, AWS CloudFront)

**Development Tools:**
- Java 21 SDK
- Node.js 20+
- Maven 3.9+
- Git version control
- IDE (IntelliJ IDEA, VS Code, etc.)

---

## 11. Open Questions

### Technical Questions
1. **Word List Source:** Which open-source word list to use? (ENABLE, Collins Scrabble Words, custom?)
2. **Word Validation:** Client-side only or server-side validation? (Recommendation: both)
3. **Game State Persistence:** LocalStorage, SessionStorage, or database? (Phase 1-2: LocalStorage, Phase 3: Database)
4. **Daily Challenge Seed:** How to generate deterministic daily words? (Date-based seed + shuffle algorithm)
5. **Multiplayer Architecture:** WebSockets, Server-Sent Events, or polling? (Recommendation: WebSockets)

### Business Questions
1. **Target Users:** Primarily developers (learning kata) or general players?
2. **Monetization:** Free forever or future premium features? (Out of scope for now)
3. **Data Privacy:** What analytics to collect? (Minimal for kata, more for production)
4. **Content Policy:** Any word filtering needed? (Recommendation: Yes, filter offensive words)

### UX Questions
1. **Tutorial:** Do we need an onboarding tutorial? (Recommendation: Optional help page)
2. **Dark Mode:** Default or user preference? (Recommendation: User preference, default light)
3. **Animations:** Speed and style preferences? (Recommendation: Match original Wordle)
4. **Mobile Keyboard:** Always show or auto-hide? (Recommendation: Auto-hide on mobile)

### Legal Questions
1. **Trademark:** Is "Wordle" trademarked? (Yes, by NYT - use different name for public release)
2. **Word List Licensing:** Are word lists open-source? (Check specific list licenses)
3. **Privacy Policy:** Required for user accounts? (Yes, if collecting user data in Phase 3)
4. **Terms of Service:** Required? (Yes, if public release)

---

## 12. Risks and Mitigations

| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|---------------------|
| Word list contains offensive words | High | Medium | Filter word list, manual review, reporting system |
| Performance issues with large user base | High | Low (Phase 1-2) | Load testing, caching, CDN, horizontal scaling |
| Dictionary API rate limits | Medium | Medium | Bundle word list locally, implement caching |
| Browser compatibility issues | Medium | Low | Test on target browsers, use polyfills |
| Security vulnerabilities | High | Low | Security audit, input validation, HTTPS, rate limiting |
| Feature creep | Medium | High | Strict scope adherence, phased approach |
| Test coverage drops | Medium | Medium | Automated coverage checks, PR reviews, TDD discipline |
| Architecture violations | Medium | Low | ArchUnit enforcement, code reviews |

---

## 13. Glossary

- **Wordle:** A daily word puzzle game where players guess a 5-letter word in 6 attempts
- **Hexagonal Architecture:** Architectural pattern that separates core business logic from external concerns (also called Ports & Adapters)
- **TDD:** Test-Driven Development - writing tests before code
- **Kata:** A coding exercise for practicing programming techniques
- **MVP:** Minimum Viable Product - simplest version that delivers core value
- **Either Pattern:** Functional programming pattern for type-safe error handling (Either<Error, Success>)
- **Value Object:** Immutable object defined by its attributes, not identity
- **Command Processor:** Pattern where commands encapsulate requests and processors execute them
- **ArchUnit:** Java library for testing architecture and design rules
- **Green Letter:** Letter in correct position (🟩)
- **Yellow Letter:** Letter in word but wrong position (🟨)
- **Gray Letter:** Letter not in word (⬜)
- **Hard Mode:** Constraint where players must use revealed hints in subsequent guesses
- **Daily Challenge:** Puzzle that changes once per day, same for all players
- **Guess Distribution:** Histogram showing how many guesses typically needed to win

---

## Document Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-20 | Jurgen De Smet | Initial PRD creation |

---

**END OF DOCUMENT**
