# CodeKata

CodeKata is a platform for developers who want to sharpen their Ruby skills through practice, competition, and community. Solve challenges on your own, race a friend head-to-head, or talk through a problem in the discussion forum — it's all here in one place.

---

## What it does

**Code challenges** — A growing library of Ruby problems across easy, medium, and hard difficulty. Each challenge runs your code against real test cases and tells you exactly what passed and what didn't.

**Head-to-head duels** — Invite a friend to solve the same challenge at the same time. First one to pass all test cases wins. The editor syncs live so you can see each other's output as it happens.

**Collaborative editor** — Share a room link and write code together in real time. Useful for pair programming, walkthroughs, or just getting unstuck.

**Discussions** — A community forum for asking questions, sharing solutions, and talking through approaches. Threads are votable so the best answers surface naturally.

**Notifications & connections** — Send connection requests to other users, get notified when someone invites you to a duel or replies to your post.

---

## Tech stack

- **Ruby on Rails 7** — backend, routing, models
- **PostgreSQL** — primary database
- **Redis** — real-time pub/sub, session storage
- **Hotwire (Turbo + Stimulus)** — fast, SPA-like navigation without a JS framework
- **ActionCable** — WebSocket layer powering the live editor and notifications
- **StimulusReflex** — reactive server-side rendering
- **CodeMirror 6** — in-browser code editor with Ruby syntax highlighting
- **Judge0** — sandboxed code execution (no `eval`, no risk)
- **Tailwind CSS** — styling

---

## Getting started

**Prerequisites:** Ruby 3.2.2, PostgreSQL, Redis, Node.js

```bash
# Clone the repo
git clone https://github.com/aniketpatidar/codekata
cd codekata

# Install dependencies
bundle install
yarn install

# Set up environment variables
cp .env.example .env
# Add your JUDGE0_API_KEY to .env

# Set up the database
rails db:create db:migrate db:seed

# Start everything
bin/dev
```

Then open `http://localhost:3000`.

---

## Environment variables

| Variable | Description |
|---|---|
| `JUDGE0_API_KEY` | Your Judge0 API key for sandboxed code execution |
| `REDIS_URL` | Redis connection URL (defaults to `redis://localhost:6379`) |
| `DATABASE_URL` | PostgreSQL connection string (optional, falls back to `database.yml`) |

---

## Project structure

```
app/
├── channels/        # ActionCable WebSocket channels
├── controllers/     # Request handling
├── javascript/      # Stimulus controllers, CodeMirror, ActionCable config
├── models/          # Core data models
├── reflexes/        # StimulusReflex handlers
├── services/        # Business logic (Judge0 integration, etc.)
└── views/           # ERB templates
```

---

## Roadmap

- [x] Ruby code challenges with test case runner
- [x] Real-time collaborative editor
- [x] Discussion forum with voting
- [x] Friend connections and notifications
- [ ] Head-to-head timed duels
- [ ] AI-powered hints
- [ ] Leaderboards and duel history
- [ ] Multi-language support

---

## Contributing

Pull requests are welcome. For larger changes, open an issue first to discuss what you'd like to change.

---

## License

MIT
