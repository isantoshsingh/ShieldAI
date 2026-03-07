# ShieldAI — Claude Code Instructions

## First: read the full spec before touching any code
The complete specification is at `docs/SHIELDAI_SPEC.md`. Read it entirely
before writing a single line. Every architectural decision, column name,
business rule, and edge case is in there. Do not infer where the spec is
explicit.

---

## What you are building
Multi-tenant SaaS Rails app. A Chrome extension detects which AI tools
employees visit. A Rails dashboard shows admins that usage data. Each
organisation is completely isolated — no org can see another's data.

**Stack:** Rails 8.x · PostgreSQL 16+ · Solid Queue · Hotwire · Tailwind v3 ·
Chrome MV3 extension · Kamal deployment

---

## Non-negotiable rules

### Multi-tenancy (highest risk area)
- Every query on tenant data goes through `current_organisation`. No exceptions.
- Never call `User.find(params[:id])` in org-facing controllers.
  Always `current_organisation.users.find(params[:id])`.
- Never query `DetectionEvent`, `DailySummary`, or `User` without an
  `organisation_id` filter.
- Read `docs/SHIELDAI_SPEC.md` Section 9 before building any controller.

### Authorisation
- Do not add Pundit, CanCanCan, or any authorisation gem. Use simple
  `before_action` helpers as specified in the spec (Sections 2 and 8).
- Three roles: `super_admin`, `org_admin`, `org_member`. Stored as strings.

### Devise
- Modules: `database_authenticatable` and `rememberable` only.
- No `registerable`, `recoverable`, or `confirmable`.
- Signup is handled by a custom `SignupsController`, not Devise registrations.
- Add `config.navigational_formats = ["*/*", :html]` to avoid Turbo conflicts.

### Gems
- Do not add gems not listed in the spec. The full list is in
  `docs/SHIELDAI_SPEC.md` Section 3.

### Secrets
- All secrets via environment variables. See spec Section 4 for the full list.
- Create `.env.example` with placeholder values. Never hardcode credentials.

---

## Build order
Follow Section 19 of the spec exactly. Do not reorder steps.

**Step 7 is a hard gate:** write the tenancy isolation RSpec spec before
building any dashboard UI. If it does not pass, stop and fix it before
continuing.

After each step:
1. Run `bundle exec rspec` — fix all failures before proceeding.
2. Verify expected outputs (record counts, HTTP responses) as noted in
   Section 19.
3. Commit with message format: `Step N: <description>` e.g.
   `Step 4: API endpoint with Rack::Attack`

---

## Key files to create
```
shieldai/
├── CLAUDE.md                  ← this file
├── docs/
│   └── SHIELDAI_SPEC.md       ← full spec, read this first
├── .env.example               ← all env vars with placeholder values
└── PROGRESS.md                ← update after every completed step
```

---

## PROGRESS.md
Maintain `PROGRESS.md` throughout the build. After completing each step,
update it with:
- Step number and description
- What was built
- Test results
- Any deviations from the spec (there should be none, but note if any)

This allows resuming work across sessions without re-reading the codebase.

---

## Done criteria
Do not declare the build complete until all of the following pass:

- [ ] Public signup creates org + org_admin in a single transaction
- [ ] Org A admin cannot access Org B employee records (returns 404, not 403)
- [ ] super_admin redirected to `/super`, cannot access org dashboard routes
- [ ] Chrome extension event appears in the correct org's dashboard
- [ ] `DailySummaryJob` populates `daily_summaries` with correct `organisation_id`
- [ ] All RSpec specs listed in spec Section 18 pass
- [ ] Bullet gem reports zero N+1 queries across all dashboard pages
