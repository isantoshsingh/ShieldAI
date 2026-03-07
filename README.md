# ShieldAI

AI Tool Discovery & Governance platform. A multi-tenant SaaS application that detects employee visits to AI tool websites via a Chrome extension and surfaces usage data on an admin dashboard.

## Stack

- Ruby 3.3.6 / Rails 8.x
- PostgreSQL 16+
- Solid Queue (background jobs)
- Hotwire (Turbo Frames & Streams)
- Tailwind CSS v3
- Chrome MV3 Extension
- Kamal (deployment)

## Getting Started

### Prerequisites

- Ruby 3.3.x
- PostgreSQL 16+
- Node.js (for asset pipeline)

### Setup

```bash
cp .env.example .env
# Edit .env with your values

bundle install
rails db:create db:migrate db:seed
```

### Environment Variables

All configuration is via environment variables. See `.env.example` for the full list including:

- `DATABASE_URL` — PostgreSQL connection string (production)
- `SECRET_KEY_BASE` — Rails secret key
- `SHIELDAI_HOST` — Public hostname (e.g. `shieldai.example.com`)
- `SEED_SUPER_ADMIN_EMAIL` / `SEED_SUPER_ADMIN_PASSWORD` — Super admin credentials
- `SEED_ORG_NAME` / `SEED_ORG_ADMIN_EMAIL` / `SEED_ORG_ADMIN_PASSWORD` — First org setup
- SMTP settings for email delivery

### Running

```bash
# Development
bin/dev

# Or manually
rails server
```

### Tests

```bash
bundle exec rspec
```

## Architecture

### Roles

| Role | Access |
|------|--------|
| `super_admin` | `/admin` namespace only. Views all organisations. No org dashboard access. |
| `org_admin` | Full org dashboard. Manage employees, AI tools, reports, CSV export. |
| `org_member` | Read-only org dashboard. No employee management or exports. |

### Multi-Tenancy

Every query on tenant data is scoped through `current_organisation`. Organisations are fully isolated — no org can access another's data. Cross-org access returns 404, not 403.

### Key Components

- **Dashboard** — Stats cards, recent events, employee risk levels, usage charts
- **Employees** — CRUD with search, department/status filters, token management
- **AI Tools** — 35 pre-seeded tools across 6 categories, approval toggle via Turbo Streams
- **Reports** — Date range filtering, top tools/employees, CSV export via background job
- **Admin** — Super admin view of all organisations, users, and cross-org stats
- **API** — `POST /api/v1/detection_events` for Chrome extension event ingestion

### Background Jobs

| Job | Schedule | Purpose |
|-----|----------|---------|
| `DailySummaryJob` | Daily 00:30 UTC | Aggregates events into daily_summaries |
| `CleanupJob` | Weekly Sunday 02:00 UTC | Deletes detection_events older than 90 days |
| `CsvExportJob` | On demand | Generates CSV report and emails it |

### Chrome Extension

See [docs/CHROME_EXTENSION.md](docs/CHROME_EXTENSION.md) for installation and configuration.

## Deployment

Uses Kamal. See `config/deploy.yml` and `Procfile.production`.

```bash
kamal setup
kamal app exec "rails db:migrate"
kamal app exec "rails db:seed"
```

## License

Proprietary. All rights reserved.
