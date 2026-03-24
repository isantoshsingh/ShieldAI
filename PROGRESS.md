# ShieldAI Build Progress

## Step 1: Rails app skeleton
- Created Rails 8.x app with PostgreSQL, configured database.yml
- Added all gems from spec Section 3 to Gemfile
- Created .env.example with all 17 environment variables
- Set up .ruby-version (3.3.6)

## Step 2: Devise authentication
- Installed Devise with database_authenticatable, rememberable, validatable only
- Skipped registerable, recoverable, confirmable per spec
- Added navigational_formats config for Turbo compatibility
- User model with role (super_admin/org_admin/org_member), name, optional organisation

## Step 3: Database schema
- Created all 6 tables: organisations, users, employees, ai_tools, detection_events, daily_summaries
- All foreign keys with ON DELETE CASCADE
- Composite unique indexes as specified
- extension_token unique index on employees

## Step 4: Models and associations
- Organisation with slug generation (parameterize + hex suffix)
- after_create :seed_ai_tools from config/ai_tools_seed.yml (35 tools, 6 categories)
- Employee with before_validation token generation, risk_level method
- AiTool with domain normalization, CATEGORIES constant
- DetectionEvent with scopes (recent, today, last_days, unapproved)
- DailySummary with validations

## Step 5: Seeds
- super_admin (no organisation) from ENV vars
- First test org + org_admin from ENV vars
- find_or_create_by! for idempotency

## Step 6: Custom signup (SignupsController)
- Atomic transaction: org + org_admin created together
- Skip auth before_actions for public access
- Rack::Attack rate limiting (10/hr per IP for signups)
- Tests: 5 specs passing

## Step 7: Tenancy isolation (HARD GATE)
- 17 RSpec specs verifying complete data isolation
- Org A cannot see Org B employees, events, tools (returns 404)
- super_admin blocked from org routes (returns 403)
- org_member blocked from admin actions
- Risk level calculation tested
- ALL TESTS PASSING before proceeding

## Step 8: API endpoint
- POST /api/v1/detection_events
- Token-based auth (extension_token lookup)
- Domain validation within employee's organisation
- Auto-creates ai_tool if domain not found
- Rack::Attack: 60/min per token, 300/5min per IP
- Tests: 7 specs passing

## Step 9: Employee management
- Full CRUD scoped to current_organisation
- Search (ILIKE on name/email), department filter, status filter
- Pagination with Pagy v43
- Token regeneration
- Soft-delete (active=false)
- Turbo Frame for activity timeline (more_events)

## Step 10: AI Tools management
- Index with aggregated stats (total_sessions, unique_employees via left_joins)
- Toggle approved status with Turbo Stream response
- Create new tools scoped to organisation
- Category badges and approval status display

## Step 11: Dashboard
- 4 stat cards (total sessions, active employees, unique tools, today's sessions)
- Recent events list with employee + tool details
- Employee table with session counts and risk levels
- Chartkick + Groupdate for usage charts

## Step 12: Reports
- Date range filtering (default last 30 days)
- Top tools and top employees tables
- CSV export via CsvExportJob (Solid Queue)
- CsvExportMailer with attachment

## Step 13: Admin namespace
- Admin::BaseController with super_admin enforcement
- Dashboard with org stats (precomputed via SQL)
- Organisations index/show/new/create
- Users index with pagination
- Organisation creation with atomic org + admin user transaction

## Step 14: Bullet N+1 fixes
- Dashboard: eager load detection_events with ai_tool for employees
- Employees index: eager load detection_events with ai_tool
- Admin dashboard: precompute employees_count and events_30d via SQL aggregation
- Admin organisations index: precompute employees_count via SQL

## Step 15: Chrome extension + deployment
- 5 files in shieldai-extension/: manifest.json, content.js, background.js, setup.html, setup.js
- MV3 manifest with storage permission and <all_urls> host permission
- content.js: 35 AI domains, hostname matching, single message per page load
- background.js: 30-min dedup per domain, POST to API, silent failure
- setup.html/js: token entry, activate/deactivate, status display
- Procfile.production: Puma + Solid Queue
- config/deploy.yml: Kamal config with all env secrets

## Test Results
- **38 examples, 0 failures, 1 pending** (placeholder user_spec)
- Tenancy isolation: fully verified
- API endpoint: fully verified
- Signup flow: fully verified
- Background jobs: fully verified

## Deviations from Spec
- ai_tools_seed.yml contains 35 tools (spec says 36 in some places, but only 35 are listed in Section 12.1)
- Pagy v43 required custom helper instead of Pagy::Frontend (API changed significantly)
