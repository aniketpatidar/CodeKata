# CodeKata — Domain Context

CodeKata is a competitive code-learning platform where developers sharpen their Ruby skills through challenges, head-to-head multi-round games, collaborative pair-programming, and a community discussion forum.

---

## Core Loop

The platform has two primary loops:

- **Competitive loop**: User → Challenge → Game — a user picks a difficulty, challenges a friend to a multi-round Game, and earns score toward the leaderboard
- **Social loop**: User → Discussion → Post — a user asks questions or shares solutions in the forum, voted on by the community

---

## Glossary

### Challenge
A Ruby coding problem with a difficulty tier (easy / medium / hard), a set of test cases, and a method template the solver must implement. Challenges are the unit of competition in Game Rounds and the unit of completion in a user's profile.

- Avoid: "problem", "exercise", "kata" (reserved for the brand, not a model term)

### Game
A multi-round head-to-head competition between two Users. The Challenger picks a round count (1, 3, or 5) and a difficulty tier; the system randomly assigns one Challenge of that difficulty to each Round. A Game moves through three statuses: `pending` (invited, not yet started) → `active` (both players coding) → `completed` (winner determined).

- **Challenger**: the User who initiates the Game
- **Opponent**: the User who accepts the Game invitation
- **Winner**: the User who wins the majority of Rounds (nullable until Game is completed)
- Avoid: "duel", "match", "race" — use "Game"

### Game Round
A single coding round within a Game. Each Round has one Challenge assigned at random (filtered by the Game's difficulty tier). The first player to pass all test cases wins the Round.

- **Round Winner**: the User who passes all tests first in a given Round (nullable until Round is completed)
- Avoid: "stage", "level" — use "Round" or "Game Round"

### Mock
A solo, timed session on a fixed Paper. The system picks Challenges for the Paper's mix (unsolved first), starts a server-side countdown, and scores the Mock when it finishes — on the last solve, on "Finish now", or lazily on the first request after the deadline. A Mock moves `in_progress` → `finished`; a User has at most one `in_progress` Mock. Mock scores never change a User's Score.

- **Mock Score**: 10 / 20 / 30 per solved easy / medium / hard Challenge, plus up to 20% time bonus when every Challenge is solved
- **Personal best**: the highest Mock Score a User has on a given Paper
- Avoid: "exam", "test", "quiz" — use "Mock"

### Paper
A code-defined preset a Mock is taken on: a challenge mix and a duration (Sprint: 3 easy / 20 min; Standard: 2 easy + 2 medium / 45 min; Marathon: 2 easy + 4 medium / 90 min).

- Avoid: "template", "format" — use "Paper"

### Score
A numeric value on each User that accumulates across completed Games. Winning a Game earns: `rounds_won + 3 (bonus) + min(opponent_score / 20, 50) - rounds_lost`. Losing earns: `rounds_won` (floored at 0). Score never decreases below 0.

- Avoid: "rating", "points", "rank" — use "Score"

### Leaderboard
A ranking of the top 10 Users by Score, displayed on the dashboard.

### Challenge Completion
A record that a specific User has passed all tests for a specific Challenge. Unique per user per challenge — completing a Challenge twice does not create two records.

### Code Evaluation
The act of submitting code to Judge0 for test execution. Triggered from the editor; results are streamed back in real time. A successful evaluation on all test cases wins the Round for that player.

### Collaborative Room
A shared real-time code editor session for a given Challenge, identified by a `room_id`. Multiple users can edit simultaneously via ActionCable. Distinct from a Game — no winner, no score, no timer.

- Avoid: "collaboration session", "pair room" — use "Collaborative Room" or just "Room"

### Discussion
A forum thread with a title, a rich-text body, and zero or more Categories. Discussions are votable (upvote / downvote) and can be pinned or closed by admins. Vote count = upvotes − downvotes.

- Avoid: "thread", "topic", "question" — use "Discussion"

### Post
A reply inside a Discussion. Has a rich-text body. Counter-cached on the parent Discussion.

- Avoid: "comment", "reply", "answer" — use "Post"

### Category
A tag that classifies a Discussion (e.g. "Ruby", "Algorithms"). Many-to-many with Discussion.

### Invitation
A friend request from one User to another. Becomes a confirmed friendship once accepted. Friendship is bidirectional — confirmed on either side counts.

- `pending`: sent, not yet accepted
- `confirmed`: accepted, both users are friends
- Avoid: "friend request", "connection" — use "Invitation"

### Notification
An in-app alert delivered to a User. Uses STI for typed notifications (game invites, game results, discussion replies, friend requests, etc.). Unread = `read_at` is nil.

### Hint
An AI-generated 2–3 sentence nudge for a Challenge, produced by Gemini given the challenge description and the user's current code. Gated by the `ai_hints_enabled` AppSetting.

### AppSetting
A key/value feature flag managed by admins. Currently controls `ai_hints_enabled`. Boolean value.

---

## User Identity

- **Slug**: a unique, URL-safe username auto-generated from the user's full name. Used in profile URLs (`/users/:slug`) and as the primary public identifier.
- **Admin**: `User#id == 1` is hardcoded as the admin. No role table.
- **Score**: integer on `User`, accumulated across completed Games. Never decreases below 0.
- **Online presence**: tracked via Kredis; broadcast over `OnlineChannel`.
- **Avatar**: an image attached to a User via ActiveStorage.

---

## Enums

| Model | Field | Values |
|-------|-------|--------|
| Challenge | `difficulty` | `easy`, `medium`, `hard` |
| Game | `status` | `pending`, `active`, `completed` |
| Game | `round_count` | `1`, `3`, `5` |

---

## External Services

- **Judge0** — sandboxed code execution API. Wraps submitted Ruby code around each test case, polls for results.
- **Gemini** — AI hint generation (Gemini 2.0 Flash). Requires `GEMINI_API_KEY`.

---

## What this glossary is for

Use these terms exactly when naming issues, test descriptions, refactor proposals, and PR titles. If a concept you need isn't here, don't invent a synonym — either use the nearest term or flag the gap.
