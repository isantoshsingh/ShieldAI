# ShieldAI

Shadow AI discovery and governance platform. Detects when employees use AI tools (ChatGPT, Claude, Gemini, and 17+ others) and surfaces usage in a central dashboard — without reading prompts or blocking access.

Built with Rails 7.2, Hotwire, and a Chrome extension (Manifest V3).

-----

## What It Does

- **Chrome extension** silently detects visits to known AI tool domains
- **Rails dashboard** shows who’s using what, when, and how often
- **Detect-only** — no prompt inspection, no blocking (by design for MVP)
- **27-user internal pilot** on Mac + Chrome

-----

## Tech Stack

|Layer    |Technology                       |
|---------|---------------------------------|
|Backend  |Ruby on Rails 7.2 (API + Hotwire)|
|Database |PostgreSQL 16                    |
|Jobs     |Sidekiq + Redis                  |
|Frontend |Turbo + Stimulus + Chart.js      |
|Auth     |Magic link email (no passwords)  |
|Extension|Chrome Manifest V3 (JavaScript)  |
|Hosting  |Render.com / Fly.io              |

-----

## Project Structure

```
shieldai/
├── app/
│   ├── controllers/
│   │   ├── api/v1/
│   │   │   ├── events_controller.rb
│   │   │   └── users_controller.rb
│   │   ├── dashboard_controller.rb
│   │   ├── users_controller.rb
│   │   ├── tools_controller.rb
│   │   └── auth_controller.rb
│   ├── models/
│   │   ├── user.rb
│   │   ├── ai_tool.rb
│   │   ├── event.rb
│   │   └── magic_link.rb
│   ├── views/
│   │   ├── dashboard/
│   │   ├── users/
│   │   ├── tools/
│   │   └── auth/
│   └── mailers/
│       └── auth_mailer.rb
├── extension/
│   ├── manifest.json
│   ├── background/service-worker.js
│   ├── content/detector.js
│   ├── popup/
│   ├── config/
│   │   ├── ai-tools.json       # 20 AI tool domains
│   │   └── api.js              # API base URL config
│   └── icons/
└── db/
    ├── migrate/
    └── seeds.rb                # Seeds ai_tools table
```

-----

## Getting Started

### Prerequisites

- Ruby 3.3+
- PostgreSQL 16
- Redis
- Node.js (for Sidekiq web UI assets)
- Chrome browser

### Setup

```bash
git clone https://github.com/yourorg/shieldai
cd shieldai

bundle install

cp .env.example .env
# Edit .env — see Environment Variables section below

rails db:create db:migrate db:seed

# Start all services
bin/dev
```

`bin/dev` starts Rails, Sidekiq, and CSS watching via Foreman.

### Environment Variables

```bash
# Required
DATABASE_URL=postgresql://localhost/shieldai_development
REDIS_URL=redis://localhost:6379/0
ALLOWED_EMAIL_DOMAIN=yourcompany.com     # Only this domain can activate the extension
ADMIN_EMAIL=you@yourcompany.com
SECRET_KEY_BASE=                         # rails secret

# Email (magic link login)
SMTP_HOST=smtp.postmarkapp.com
SMTP_USER=your-api-token
SMTP_PASS=your-api-token

# Extension
EXTENSION_API_URL=https://your-app.onrender.com
```

-----

## Chrome Extension

### Install (Internal Pilot)

1. Download and unzip `extension/` folder
1. Open Chrome → `chrome://extensions` → enable **Developer Mode**
1. Click **Load unpacked** → select the `extension/` folder
1. Click the ShieldAI icon → enter your work email → click **Activate**

Setup takes under 3 minutes per user.

### How It Works

The content script (`detector.js`) runs on every page load, checks the domain against `ai-tools.json`, and POSTs an event to the Rails API if matched. Events are debounced — one event per domain per 5-minute window.

**Extension → API payload:**

```json
{
  "token": "usr_xxxxxxxxxxxx",
  "event": {
    "domain": "chat.openai.com",
    "page_title": "ChatGPT",
    "detected_at": "2026-02-22T09:42:00Z",
    "session_id": "abc123"
  }
}
```

To point the extension at a different backend, edit one line in `extension/config/api.js`:

```js
export const API_BASE_URL = 'https://your-shieldai-app.onrender.com';
```

-----

## API Endpoints

|Method|Path                    |Description                              |
|------|------------------------|-----------------------------------------|
|`POST`|`/api/v1/users/activate`|Extension onboarding — returns auth token|
|`POST`|`/api/v1/events`        |Ingest a detection event                 |
|`GET` |`/api/v1/users/me`      |Extension status check                   |

All extension API calls are authenticated via a `token` field in the request body (no cookies).

-----

## Dashboard Pages

|Route       |Description                                      |
|------------|-------------------------------------------------|
|`/`         |Overview: stats, live event feed, top tools chart|
|`/users`    |Employees ranked by AI usage                     |
|`/users/:id`|Individual activity timeline                     |
|`/tools`    |All detected AI tools with usage counts          |

Login is passwordless — request a magic link from `/auth/login`.

-----

## Detected AI Tools (Seed Data)

20 domains seeded by default across 5 categories: **Chat**, **Code**, **Writing**, **Image**, **Search**.

Includes: ChatGPT, Claude, Gemini, Copilot, Perplexity, Cursor, Phind, Jasper, Copy.ai, Writesonic, Midjourney, RunwayML, Pika, ElevenLabs, Suno, Poe, You.com, and Character.AI.

Run `rails db:seed` to load them.

-----

## Database Schema

```
users          — email, name, department, token, role
ai_tools       — name, domain, category, risk_level, approved
events         — user_id, ai_tool_id, domain, page_title, detected_at, session_id
magic_links    — user_id, token, expires_at, used_at
```

-----

## Deployment (Render.com)

1. Push to GitHub
1. Create a new **Web Service** on Render → connect repo
1. Set all environment variables from `.env.example`
1. Add a **PostgreSQL** and **Redis** instance on Render
1. Set build command: `bundle install && rails db:migrate db:seed`
1. Set start command: `bundle exec puma -C config/puma.rb`
1. Add a separate **Background Worker** service with start command: `bundle exec sidekiq`
1. Update `EXTENSION_API_URL` to your Render URL → redistribute extension zip to team

-----

## Security

- Extension activations restricted to `ALLOWED_EMAIL_DOMAIN`
- API rate limited via `rack-attack`: 60 req/min per token, 10 activations/min per IP
- HTTPS enforced in production
- Magic links expire after 15 minutes

-----

## MVP Scope

**In scope:** Detection only, Mac + Chrome, 27 users, single company, admin dashboard.

**Not in scope (future):** Blocking/enforcement, PII scanning in prompts, MSP multi-tenancy, Slack alerts, mobile support, Chrome Web Store publish.

-----

## License

Private — internal use only.
