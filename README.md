# CodeKata

> [!NOTE]
> CodeKata is a coding platform for Ruby developers. 

This project helps you improve your Ruby skills. You can solve coding challenges and play games against friends. You can also write code together in real-time and talk about answers in the forum. It makes coding practice fun.

## Features

- Real-time code editor (CodeMirror 6)
- Live updates and web sockets via ActionCable
- Code evaluation against Judge0 API

## Installation

Follow these steps to install CodeKata.

> [!IMPORTANT]
> You must install Ruby 3.2.2, PostgreSQL, Redis, and Node.js first.

1. Get the code:
   ```bash
   git clone https://github.com/aniketpatidar/codekata.git
   cd codekata
   ```
2. Set up your settings:
   ```bash
   cp .env.example .env
   ```
3. Run the setup script:
   ```bash
   bin/setup
   ```

## Usage

Start the server to use CodeKata locally:
```bash
$ bin/rails server
```
Then, open `http://localhost:3000` in your web browser.

### Docker (alternative)

`docker-compose.yml` runs the app, Postgres, and Redis as containers:

```bash
docker compose up -d
```

Postgres and Redis publish to `localhost:5432` and `localhost:6379`, so commands run on the host (`bin/rails test`, `bin/rails console`, etc.) can point `DATABASE_URL`/`REDIS_URL` at `localhost` rather than a container IP — container IPs are assigned dynamically and change on every restart.

## Configuration Options

CodeKata uses environment variables for settings. You can find these in the `.env` file. Common options include:

- Database settings for PostgreSQL.
- Redis settings for live updates.
- Judge0 API keys to run code.

> [!TIP]
> Look at the `.env.example` file. It shows all the settings you can use.

## Source Code Guide

CodeKata is a normal Ruby on Rails 7 app. These folders will help you understand the code:

- `app/javascript/`: Holds the code editor files (CodeMirror 6).
- `app/channels/`: Manages live updates and web sockets (ActionCable).
- `lib/`: Contains the code that sends tests to Judge0.

## Contributing

We want your help! Please read `CONTRIBUTING.md` to learn how to add code.

> [!WARNING]
> You must run the tests before you share your changes. Also, you must run Redis on your computer so the tests can pass.

## License

MIT
