# Wordle User Stories

**Version:** 1.0
**Last Updated:** November 20, 2025
**Coverage:** Phase 1 (MVP) + Phase 2 (Core Gameplay)

---

## Milestone 1: Basic Game - "I can make a guess and see if I won"

### Story 001: Display Game Input Field

**Value:** Players can see where to enter their guess

**Behavior:** The game displays an input field where players can type their guess, along with a submit button.

**Examples:**

### Example 1: Initial game state
```
Given: the game loads
When: the page renders
Then: an input field is visible
And: a "Submit Guess" button is visible
And: the input field is empty and focused
```

**Notes:** This is the foundation for user interaction. The input field should auto-focus on page load.

---

### Story 002: Accept Alphabetic Input Only

**Value:** Players can only type valid letters, preventing input errors

**Behavior:** The input field accepts only alphabetic characters (A-Z, case-insensitive) and ignores all other keystrokes.

**Examples:**

### Example 1: Valid and invalid keystrokes
```
Given: the input field is focused
When: the player types characters <input>
Then: the input field displays <displayed>

| input      | displayed |
|------------|-----------|
| HELLO      | HELLO     |
| hello      | hello     |
| HeLLo      | HeLLo     |
| HEL12      | HEL       |
| HE@LO      | HELO      |
| H E L L O  | HELLO     |
```

**Notes:** Numbers, special characters, and spaces are silently ignored (not displayed).

---

### Story 003: Limit Input to 5 Characters

**Value:** Players can only enter exactly 5 letters, matching the game rules

**Behavior:** The input field accepts a maximum of 5 characters and prevents additional input.

**Examples:**

### Example 1: Input length limiting
```
Given: the input field is empty
When: the player types <input>
Then: the input field displays <displayed>

| input       | displayed |
|-------------|-----------|
| CRANE       | CRANE     |
| CRANES      | CRANE     |
| CRANESBIRD  | CRANE     |
| CRA         | CRA       |
```

**Notes:** The 6th and subsequent characters are ignored, not displayed.

---

### Story 004: Submit Guess with 5 Letters

**Value:** Players can submit a complete guess and receive feedback

**Behavior:** When the player has entered exactly 5 letters and clicks submit (or presses Enter), the guess is submitted and validated.

**Examples:**

### Example 1: Submit complete guess
```
Given: the target word is "CRANE"
And: the input field contains "HOUSE"
When: the player clicks "Submit Guess" (or presses Enter)
Then: the guess is processed
And: the input field is cleared
```

### Example 2: Cannot submit incomplete guess
```
Given: the input field contains <input>
When: the player clicks "Submit Guess"
Then: the result is <outcome>

| input | outcome                                  |
|-------|------------------------------------------|
| CRAN  | Error: "Word must be exactly 5 letters"  |
| CRA   | Error: "Word must be exactly 5 letters"  |
| C     | Error: "Word must be exactly 5 letters"  |
| ""    | Error: "Word must be exactly 5 letters"  |
```

**Notes:** Submit button should be disabled when input length ≠ 5.

---

### Story 005: Check Exact Match (Win Condition)

**Value:** Players know immediately when they've guessed the correct word

**Behavior:** After submitting a guess, if the guess exactly matches the target word (case-insensitive), the game displays a win message.

**Examples:**

### Example 1: Exact match wins
```
Given: the target word is "CRANE"
When: the player submits guess <guess>
Then: the result is <outcome>

| guess | outcome            |
|-------|--------------------|
| CRANE | "You won!"         |
| crane | "You won!"         |
| CrAnE | "You won!"         |
| HOUSE | No message yet     |
| CRATE | No message yet     |
```

**Notes:** Comparison is case-insensitive. Win message should be clear and celebratory.

---

### Story 006: Show "Try Again" for Incorrect Guess

**Value:** Players receive feedback that their guess was incorrect and can continue playing

**Behavior:** After submitting a guess that doesn't match the target word, the game displays a message indicating the guess was incorrect.

**Examples:**

### Example 1: Incorrect guess feedback
```
Given: the target word is "CRANE"
When: the player submits guess <guess>
Then: the message is <message>

| guess | message                   |
|-------|---------------------------|
| HOUSE | "Incorrect. Try again."   |
| CRATE | "Incorrect. Try again."   |
| CRANE | "You won!"                |
```

**Notes:** The message should encourage the player to keep trying.

---

## Milestone 2: Game Progress - "I can see my attempts and know when I've lost"

### Story 007: Track Number of Guesses

**Value:** Players know how many attempts they've used

**Behavior:** The game tracks and displays the number of guesses the player has made (e.g., "Guess 1/6", "Guess 2/6").

**Examples:**

### Example 1: Guess counter increments
```
Given: the game has started
And: the counter shows "Guess 0/6"
When: the player submits valid guesses in sequence
Then: the counter updates as follows:

| action         | counter display |
|----------------|-----------------|
| Submit guess 1 | Guess 1/6       |
| Submit guess 2 | Guess 2/6       |
| Submit guess 3 | Guess 3/6       |
| Submit guess 6 | Guess 6/6       |
```

**Notes:** Counter updates immediately after each valid guess submission.

---

### Story 008: Prevent Guesses After 6 Attempts

**Value:** Players cannot submit more than 6 guesses, enforcing game rules

**Behavior:** After the player has made 6 incorrect guesses, the input field and submit button are disabled.

**Examples:**

### Example 1: Disable input after 6 guesses
```
Given: the player has made 6 incorrect guesses
When: the game updates the UI
Then: the input field is disabled
And: the submit button is disabled
And: the player cannot type in the input field
```

### Example 2: Win before 6 attempts
```
Given: the player has made 3 guesses
When: the player guesses correctly
Then: the input field is disabled
And: the submit button is disabled
```

**Notes:** Disable both on win and after 6 failed attempts.

---

### Story 009: Display Loss Message After 6 Failed Attempts

**Value:** Players know they've lost and the game has ended

**Behavior:** After 6 incorrect guesses, the game displays a loss message and reveals the target word.

**Examples:**

### Example 1: Loss after 6 attempts
```
Given: the target word is "CRANE"
And: the player has made 5 incorrect guesses
When: the player submits a 6th incorrect guess "HOUSE"
Then: the message is "Game Over! The word was: CRANE"
And: the input is disabled
```

### Example 2: No loss message before 6 attempts
```
Given: the player has made <count> incorrect guesses
When: the game updates
Then: the loss message <shown>

| count | shown              |
|-------|--------------------|
| 1     | Not shown          |
| 3     | Not shown          |
| 5     | Not shown          |
| 6     | Shown              |
```

**Notes:** Loss message should clearly show the target word.

---

### Story 010: Display Win Message When Correct

**Value:** Players receive positive feedback and know the game has ended

**Behavior:** When the player guesses the correct word, display an encouraging win message based on how many attempts it took.

**Examples:**

### Example 1: Win messages by attempt count
```
Given: the target word is "CRANE"
When: the player guesses correctly on attempt <attempt>
Then: the message is <message>

| attempt | message        |
|---------|----------------|
| 1       | "Genius!"      |
| 2       | "Magnificent!" |
| 3       | "Impressive!"  |
| 4       | "Splendid!"    |
| 5       | "Great!"       |
| 6       | "Phew!"        |
```

**Notes:** Different messages add personality and reward faster solutions.

---

## Milestone 3: Letter Feedback - "I get clues about which letters are correct"

### Story 011: Show Green for Correct Position

**Value:** Players know which letters are in the correct position

**Behavior:** After submitting a guess, letters that match the target word at the same position are displayed with a green background.

**Examples:**

### Example 1: Green letter highlighting
```
Given: the target word is "CRANE"
When: the player submits guess <guess>
Then: the letters are colored <colors>

| guess | colors (Green=G, Gray=X)          |
|-------|-----------------------------------|
| CRANE | G-G-G-G-G (all green)             |
| CRATE | G-G-G-X-G (C, R, A, E green)      |
| HOUSE | X-X-X-X-G (only E green)          |
| STONE | X-X-X-G-G (N, E green)            |
| XRXNX | X-G-X-G-X (R, N green)            |
```

**Notes:** Green indicates exact position match. Use color code: Green = #6aaa64 (Wordle green).

---

### Story 012: Show Gray for Letters Not in Word

**Value:** Players know which letters to avoid in future guesses

**Behavior:** After submitting a guess, letters that do not appear anywhere in the target word are displayed with a gray background.

**Examples:**

### Example 1: Gray letter highlighting
```
Given: the target word is "CRANE"
When: the player submits guess <guess>
Then: the letters are colored <colors>

| guess | colors (Green=G, Gray=X)     |
|-------|------------------------------|
| HOUSE | X-X-X-X-G (H,O,U,S gray)     |
| BIKES | X-X-X-G-X (B,I,K,S gray)     |
| FJORD | X-X-X-G-X (F,J,O,D gray)     |
```

**Notes:** Gray means letter doesn't exist in target word. Use color code: Gray = #787c7e.

---

### Story 013: Show Yellow for Correct Letter, Wrong Position

**Value:** Players know which letters are in the word but need to be repositioned

**Behavior:** After submitting a guess, letters that exist in the target word but are in the wrong position are displayed with a yellow background.

**Examples:**

### Example 1: Yellow letter highlighting
```
Given: the target word is "CRANE"
When: the player submits guess <guess>
Then: the letters are colored <colors>

| guess | colors (Green=G, Yellow=Y, Gray=X) |
|-------|-------------------------------------|
| ARENA | Y-Y-Y-Y-Y (all yellow)              |
| NACRE | Y-Y-G-Y-Y (A green, others yellow)  |
| RAINS | G-G-X-Y-X (C,R green, A yellow)     |
```

**Notes:** Yellow means letter exists but wrong position. Use color code: Yellow = #c9b458.

---

### Story 014: Handle Duplicate Letters - One in Word

**Value:** Players get accurate feedback when their guess has duplicate letters but the target has only one

**Behavior:** When the guess contains duplicate letters and the target word contains fewer instances of that letter, only the correctly positioned or first occurrence gets colored (green/yellow), others are gray.

**Examples:**

### Example 1: Duplicate letter handling (target has one, guess has two)
```
Given: the target word is "CRANE"
When: the player submits guess <guess>
Then: the letters are colored <colors>

| guess | colors (Green=G, Yellow=Y, Gray=X) | explanation                          |
|-------|-------------------------------------|--------------------------------------|
| ARRAY | Y-G-G-X-X                           | First A yellow, second A gray        |
| ERASE | Y-G-Y-X-G                           | First E yellow, second E green       |
| ARENA | Y-G-Y-Y-Y                           | A yellow, R green, E,N,A yellow      |
```

### Example 2: Target has duplicate, guess has one
```
Given: the target word is "GEESE"
When: the player submits guess <guess>
Then: the letters are colored <colors>

| guess | colors                | explanation              |
|-------|-----------------------|--------------------------|
| CREAM | X-G-Y-X-X             | R gray, E green, A gray  |
| BIKES | X-X-X-G-X             | E green (position 4)     |
```

**Notes:** This is the most complex color logic. Green takes priority over yellow. If target has 1 'E' and guess has 2 'E's, only one gets colored (green if position matches, else yellow for first occurrence).

---

### Story 015: Display Previous Guesses in a List

**Value:** Players can see all their previous guesses and the feedback for each

**Behavior:** The game displays a vertical list of all submitted guesses, with each letter color-coded (green/yellow/gray).

**Examples:**

### Example 1: Guess history display
```
Given: the target word is "CRANE"
And: the player has submitted guesses in order: "HOUSE", "CRATE", "CRANE"
When: the UI renders
Then: the display shows:
  Guess 1: H(gray) O(gray) U(gray) S(gray) E(green)
  Guess 2: C(green) R(green) A(green) T(gray) E(green)
  Guess 3: C(green) R(green) A(green) N(green) E(green)
```

**Notes:** Each guess displayed in chronological order (oldest at top). Colors should match the feedback rules from previous stories.

---

## Milestone 4: Visual Grid - "I see the classic Wordle grid layout"

### Story 016: Display 6x5 Empty Grid on Game Start

**Value:** Players see the familiar Wordle grid layout, setting expectations for 6 attempts

**Behavior:** When the game loads, display a 6-row by 5-column grid of empty letter boxes, representing the 6 possible guesses.

**Examples:**

### Example 1: Initial grid state
```
Given: the game has just loaded
When: the UI renders
Then: a 6x5 grid is displayed
And: all 30 boxes are empty
And: all boxes have a neutral border color
```

**Notes:** Use clean, minimal box design. Empty boxes should have a light border (#d3d6da).

---

### Story 017: Fill Grid Row with Current Guess (Live Preview)

**Value:** Players see their typed letters appear in the grid in real-time

**Behavior:** As the player types in the input field, the letters appear in the current row of the grid (not just in the input field).

**Examples:**

### Example 1: Live typing preview
```
Given: the player is on guess 1 (row 1 of grid is active)
When: the player types <input>
Then: row 1 displays <display>

| input | display in row 1          |
|-------|---------------------------|
| C     | [C][ ][ ][ ][ ]           |
| CR    | [C][R][ ][ ][ ]           |
| CRA   | [C][R][A][ ][ ]           |
| CRAN  | [C][R][A][N][ ]           |
| CRANE | [C][R][A][N][E]           |
```

**Notes:** Letters appear in real-time as user types. Active row should be visually indicated.

---

### Story 018: Apply Colors to Grid Row After Guess Submission

**Value:** Players see their guess feedback directly in the grid with colors

**Behavior:** After submitting a guess, the current row's letters are colored (green/yellow/gray) according to the feedback rules, and the active row moves to the next line.

**Examples:**

### Example 1: Grid row coloring after submission
```
Given: the target word is "CRANE"
And: the player is on guess 1
When: the player submits "HOUSE"
Then: row 1 displays: [H(gray)][O(gray)][U(gray)][S(gray)][E(green)]
And: row 2 becomes the active row
And: the input field is cleared
```

### Example 2: Multiple guesses in grid
```
Given: the target word is "CRANE"
And: the player has submitted "HOUSE", then "CRATE"
When: the UI renders
Then: the grid shows:
  Row 1: [H(gray)][O(gray)][U(gray)][S(gray)][E(green)]
  Row 2: [C(green)][R(green)][A(green)][T(gray)][E(green)]
  Row 3-6: Empty rows
```

**Notes:** Each submitted guess gets colored and locked in the grid. Active row moves down after each submission.

---

### Story 019: Disable Grid Input After Game End

**Value:** Players cannot modify the grid after winning or losing

**Behavior:** After the game ends (win or 6 failed attempts), the grid becomes read-only and displays the final state.

**Examples:**

### Example 1: Grid locked after win
```
Given: the player has won on guess 3
When: the game ends
Then: rows 1-3 display the submitted guesses with colors
And: rows 4-6 remain empty
And: no row is active (no typing preview)
And: the grid is read-only
```

### Example 2: Grid locked after loss
```
Given: the player has lost after 6 attempts
When: the game ends
Then: all 6 rows display the submitted guesses with colors
And: no row is active
And: the grid is read-only
```

**Notes:** Visual indication that game is over (e.g., subtle animation or final state styling).

---

## Milestone 5: Word Validation - "The game prevents invalid words"

### Story 020: Validate Guess Against Dictionary

**Value:** Players can only submit real English words, ensuring fair gameplay

**Behavior:** When the player submits a guess, the game checks if the word exists in a valid word list. If not, the guess is rejected with an error message.

**Examples:**

### Example 1: Valid vs invalid words
```
Given: the game has a word list containing common 5-letter English words
When: the player submits guess <guess>
Then: the result is <result>

| guess  | result                               |
|--------|--------------------------------------|
| HOUSE  | Accepted (valid word)                |
| CRANE  | Accepted (valid word)                |
| STONE  | Accepted (valid word)                |
| XYZAB  | Rejected: "Not in word list"         |
| ABCDE  | Rejected: "Not in word list"         |
| ZZZZZ  | Rejected: "Not in word list"         |
```

**Notes:** Use a curated word list (e.g., common 5-letter English words). Error message should be clear and non-blocking (allow retry).

---

### Story 021: Show Clear Error for Invalid Words

**Value:** Players understand why their guess was rejected and can try again

**Behavior:** When a guess is rejected due to not being in the word list, display a clear error message that disappears after the next input.

**Examples:**

### Example 1: Error message display and dismissal
```
Given: the player has typed "XYZAB"
When: the player clicks Submit
Then: the error "Not in word list" is displayed prominently
And: the input field is cleared
And: the input field remains focused

Given: the error "Not in word list" is showing
When: the player starts typing a new guess
Then: the error message disappears
```

**Notes:** Error should be visible but not modal (don't block interaction). Auto-dismiss on next input for smooth UX.

---

### Story 022: Case-Insensitive Word Validation

**Value:** Players can type in any case and the game normalizes it

**Behavior:** The game accepts guesses in any case (uppercase, lowercase, mixed) and normalizes them for validation and comparison.

**Examples:**

### Example 1: Case normalization
```
Given: the target word is "CRANE"
And: the word list contains "CRANE"
When: the player submits guess <guess>
Then: the result is <result>

| guess | result                     |
|-------|----------------------------|
| CRANE | Accepted and checked       |
| crane | Accepted and checked       |
| Crane | Accepted and checked       |
| CrAnE | Accepted and checked       |
```

**Notes:** Convert all input to uppercase (or lowercase) consistently for validation and comparison. Display in grid should be uppercase for consistency.

---

## Summary

**Total Stories:** 22

**Milestones:**
1. **Basic Game** (Stories 1-6): Input, validation, win/loss detection
2. **Game Progress** (Stories 7-10): Attempt tracking, game-over conditions
3. **Letter Feedback** (Stories 11-15): Color-coded hints, duplicate handling, guess history
4. **Visual Grid** (Stories 16-19): Classic Wordle grid layout and interaction
5. **Word Validation** (Stories 20-22): Dictionary checking, error handling

**User Feedback Loop:**
- After Milestone 1: Players can play a simple yes/no guessing game
- After Milestone 2: Players can see progress and know when they've lost
- After Milestone 3: Players get helpful color-coded feedback
- After Milestone 4: Players see the classic Wordle grid experience
- After Milestone 5: Players have a complete, polished Wordle game

---

**END OF DOCUMENT**
