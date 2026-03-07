  
**ShieldAI**

MVP Specification  —  v3.0  Multi-Tenant SaaS

| Field | Value |
| :---- | :---- |
| Product | ShieldAI — AI Tool Discovery & Governance |
| Spec version | v3.0 — Multi-Tenant SaaS (supersedes v2.0 single-org pilot spec) |
| Stack | Rails 8.x · PostgreSQL 16+ · Solid Queue · Chrome MV3 |
| Deployment model | Single SaaS deployment, multiple organisations, fully scoped data |
| Initial test org | 27-person internal team — seeded via db/seeds.rb |
| Billing | None in MVP. Free access during testing phase. Billing added post-launch. |
| Primary reader | Developer building from scratch — no prior context assumed |

*This document is the single source of truth. Every architectural decision, column name, business rule, role, and scoping constraint is specified here. Follow the spec exactly. When in doubt, ask rather than infer.*

# **1\. Project Overview**

ShieldAI is a multi-tenant SaaS platform. A single Rails application and a single database serve all organisations. Every piece of data is strictly scoped to its organisation — no organisation can ever access another organisation's data.

The system has two components: (1) a Chrome extension installed on employee machines that silently detects visits to known AI tool domains, and (2) a Rails web dashboard where administrators view that usage data.

| What this build must NOT do |
| :---- |
| No reading of page content, prompt text, form values, or keystrokes. The extension records domain name and page title only. No blocking of AI tool access. Detection and visibility only. No email alerts or Slack notifications. No billing or subscription logic. Free access during testing phase. No data leakage between organisations under any circumstance. |

# **2\. Roles & Permissions**

Three roles exist, stored as a plain string column on the users table. Role checks are enforced in controllers, not just views.

| Role | Who they are and what they can do |
| :---- | :---- |
| super\_admin | You, the product owner. One super\_admin exists in the system, created by db/seeds.rb only — no UI creation. Can access the /admin namespace to see all organisations, provision new orgs manually, and view cross-org data. Cannot access the org-scoped dashboard routes (/dashboard, /employees, etc.). Super admin has no organisation\_id. |
| org\_admin | The administrator of a single organisation. Created automatically when an org self-signs up (they are the org creator), or manually provisioned by super\_admin. Can: add/remove employees, manage AI tool approvals for their org, view all dashboard data for their org, export CSV reports. Cannot see any other org's data. |
| org\_member | A read-only dashboard user within a single organisation. Created by org\_admin only. Can: view dashboard, employee list, AI tools list, and reports for their own org. Cannot: add/remove employees, toggle approvals, export data. This is for internal staff who need visibility but not admin rights. |

| Critical distinction |
| :---- |
| Employees being monitored by the Chrome extension do NOT need a ShieldAI user account. They are represented by employee records (Section 5.3) and identified only by their extension\_token. A user account (org\_admin or org\_member) is only needed by someone who logs in to the dashboard. |

# **3\. Tech Stack & Gem List**

| Layer | Technology |
| :---- | :---- |
| Ruby | 3.3.x — pin with a .ruby-version file in the repo root |
| Framework | Rails 8.x (latest stable at build time) |
| Database | PostgreSQL 16+ |
| Background jobs | Solid Queue — ships with Rails 8, no Redis required |
| Auth | Devise — email \+ password only. No OAuth in MVP. |
| Frontend | Hotwire: Turbo Drive \+ Turbo Frames \+ Turbo Streams \+ Stimulus. No React or Vue. |
| CSS | Tailwind CSS v3 via tailwindcss-rails gem |
| Charts | chartkick gem \+ groupdate gem |
| Pagination | pagy gem (v9+) |
| Rate limiting | rack-attack gem |
| N+1 detection | bullet gem — development group only |
| Browser extension | Chrome Manifest V3 — vanilla JS, no build step, no npm |
| Deployment | Kamal 2.x — default Rails 8 deployer |

**Gemfile additions beyond Rails defaults:**

| gem 'devise' gem 'chartkick' gem 'groupdate' gem 'pagy' gem 'rack-attack' group :development do   gem 'bullet' end |
| :---- |

Exact rails new command:

| rails new shieldai \--database=postgresql \--asset-pipeline=tailwind \--skip-action-mailer=false |
| :---- |

Do not use \--api flag. ShieldAI needs the full stack: sessions, flash, views, ActionMailer.

# **4\. Environment Variables**

All secrets in environment variables, never committed. Create .env.example with placeholder values. Use dotenv-rails in development only.

| Variable | Purpose |
| :---- | :---- |
| DATABASE\_URL | PostgreSQL connection string. e.g. postgres://user:pass@host:5432/shieldai\_production |
| SECRET\_KEY\_BASE | Rails secret. Generate with: rails secret |
| SHIELDAI\_HOST | Public hostname. e.g. app.shieldai.com — used in emails and the extension API\_URL |
| SMTP\_ADDRESS | SMTP server hostname |
| SMTP\_PORT | SMTP port — typically 587 |
| SMTP\_USERNAME | SMTP auth username |
| SMTP\_PASSWORD | SMTP auth password |
| SMTP\_DOMAIN | SMTP HELO domain — match SHIELDAI\_HOST |
| MAILER\_FROM | From address for all outbound email. e.g. noreply@shieldai.com |
| SEED\_SUPER\_ADMIN\_EMAIL | Email for the seeded super\_admin user |
| SEED\_SUPER\_ADMIN\_PASSWORD | Password for the seeded super\_admin user |
| SEED\_ORG\_NAME | Name of the first test organisation (your 27-person team) |
| SEED\_ORG\_ADMIN\_EMAIL | Email for the first org\_admin user |
| SEED\_ORG\_ADMIN\_PASSWORD | Password for the first org\_admin user |
| RAILS\_ENV | Set to production on the server |
| RAILS\_LOG\_TO\_STDOUT | Set to enabled in production |
| RAILS\_SERVE\_STATIC\_FILES | Set to enabled if no reverse proxy is serving assets |

# **5\. Database Schema**

Create these tables via Rails migrations in the order listed. All tables include Rails default timestamps (created\_at, updated\_at, both null: false). All foreign keys include on\_delete: :cascade unless stated otherwise.

## **5.1 organisations**

Top-level tenant record. Every piece of data in the system is owned by an organisation.

| Column | Type / Constraints |
| :---- | :---- |
| id | bigint, primary key |
| name | string, null: false |
| slug | string, null: false, unique — auto-generated from name on create using parameterize. e.g. "acme-corp". Reserved for future use in URLs. |
| active | boolean, null: false, default: true — reserved for future suspension. Always true in MVP. |
| created\_at / updated\_at | datetime, null: false |

Index: unique on slug.

## **5.2 users**

Dashboard users only (org\_admin, org\_member, super\_admin). Not the same as monitored employees. Run rails generate devise User, then add custom columns in a separate migration.

| Column | Type / Constraints |
| :---- | :---- |
| id | bigint, primary key |
| email | string, null: false, default: "" — Devise |
| encrypted\_password | string, null: false, default: "" — Devise |
| remember\_created\_at | datetime, nullable — Devise rememberable |
| organisation\_id | bigint, nullable, foreign key → organisations — NULL for super\_admin only. on\_delete: :cascade. |
| role | string, null: false, default: "org\_admin" — values: super\_admin | org\_admin | org\_member |
| name | string, null: false |
| created\_at / updated\_at | datetime, null: false |

Indexes: unique on email. Index on organisation\_id. Index on role.

organisation\_id is nullable to accommodate super\_admin (no org). For all other roles it is required — enforced by model validation.

Do not add a department column to users. Department lives on the employee record (Section 5.3).

## **5.3 employees**

Represents a person being monitored within an organisation. Not a dashboard user account. Employees never log in to ShieldAI.

| Column | Type / Constraints |
| :---- | :---- |
| id | bigint, primary key |
| organisation\_id | bigint, null: false, foreign key → organisations, on\_delete: :cascade |
| name | string, null: false |
| email | string, null: false |
| department | string, nullable |
| extension\_token | string, null: false, unique across the whole table — the Chrome extension credential |
| active | boolean, null: false, default: true — soft-delete. Deactivated employees stop sending events but their history is preserved. |
| created\_at / updated\_at | datetime, null: false |

Indexes: unique on extension\_token. Unique composite on \[organisation\_id, email\]. Index on organisation\_id.

extension\_token is generated automatically on create via SecureRandom.urlsafe\_base64(32). It is the sole identifier used by the Chrome extension API.

## **5.4 ai\_tools**

AI tool domain list, scoped per organisation. Each org gets its own copy of the global default list on signup, so org\_admins can independently manage approvals without affecting other orgs.

| Column | Type / Constraints |
| :---- | :---- |
| id | bigint, primary key |
| organisation\_id | bigint, null: false, foreign key → organisations, on\_delete: :cascade |
| name | string, null: false |
| domain | string, null: false — e.g. "chat.openai.com" |
| category | string, null: false — values: chat | code | image | search | writing | other |
| icon\_emoji | string, null: false, default: "🤖" |
| approved | boolean, null: false, default: false |
| created\_at / updated\_at | datetime, null: false |

Index: unique composite on \[organisation\_id, domain\]. The same domain can exist in multiple orgs but only once per org.

On new organisation creation, the Organisation model's after\_create callback reads config/ai\_tools\_seed.yml and bulk-inserts ai\_tools rows for the new org. See Section 12.1 for the seed file format.

## **5.5 detection\_events**

Core event log. One row per detection. High insert volume.

| Column | Type / Constraints |
| :---- | :---- |
| id | bigint, primary key |
| organisation\_id | bigint, null: false, foreign key → organisations, on\_delete: :cascade — denormalised from employee for query performance |
| employee\_id | bigint, null: false, foreign key → employees, on\_delete: :cascade |
| ai\_tool\_id | bigint, null: false, foreign key → ai\_tools, on\_delete: :cascade |
| page\_title | string, nullable — browser tab title at moment of detection, max 255 chars |
| detected\_at | datetime, null: false — timestamp sent by extension. NOT Rails created\_at. Always use this for grouping and reporting. |
| created\_at / updated\_at | datetime, null: false |

Indexes: composite on \[organisation\_id, detected\_at\] (primary reporting query). Composite on \[employee\_id, detected\_at\]. Composite on \[ai\_tool\_id, detected\_at\]. Single on detected\_at.

organisation\_id is denormalised here for performance. The API sets it from employee.organisation\_id when creating the event. Do not derive it at query time.

## **5.6 daily\_summaries**

Pre-aggregated nightly rollup. Written only by DailySummaryJob. Never written by the API or user actions.

| Column | Type / Constraints |
| :---- | :---- |
| id | bigint, primary key |
| organisation\_id | bigint, null: false, foreign key → organisations, on\_delete: :cascade |
| employee\_id | bigint, null: false, foreign key → employees, on\_delete: :cascade |
| ai\_tool\_id | bigint, null: false, foreign key → ai\_tools, on\_delete: :cascade |
| summary\_date | date, null: false |
| session\_count | integer, null: false, default: 0 |
| created\_at / updated\_at | datetime, null: false |

Index: unique composite on \[organisation\_id, employee\_id, ai\_tool\_id, summary\_date\].

# **6\. The Scoping Rule (Read This First)**

This is the most critical section. A missing scope is a data leak between customers. Treat it as a security bug, not a code style issue.

| The golden rule |
| :---- |
| Never call Model.all, Model.find(id), or Model.where(...) directly inside a controller that serves org\_admin or org\_member users. Always start queries from the organisation scope: current\_organisation.employees.find(params\[:id\]) current\_organisation.ai\_tools.where(...) current\_organisation.detection\_events.count If a record is not found within the current org scope, Rails raises ActiveRecord::RecordNotFound — return 404\. Do not rescue and re-raise with a different message. A 404 correctly obscures whether the record exists in another org. |

## **6.1 current\_organisation helper**

Defined in ApplicationController. Returns the organisation the current user belongs to. Memoised.

| def current\_organisation   @current\_organisation ||= current\_user.organisation end helper\_method :current\_organisation |
| :---- |

For super\_admin, current\_organisation returns nil. Super admin never uses org-scoped dashboard routes — they have a separate /admin namespace.

## **6.2 authenticate\_org\_user\! (custom before\_action)**

Defined in ApplicationController. Called as before\_action on all dashboard controllers. Skipped by the Admin namespace and the API controller.

Logic in order:

1. Call authenticate\_user\! (Devise). Redirects to sign-in if not logged in.

2. If current\_user.super\_admin?, raise ActionController::Forbidden with message "Super admin must use /admin routes." (Returns 403.)

3. Set @organisation \= current\_organisation.

Result: org\_admin and org\_member users can only access their own organisation's data. super\_admin is blocked from org-scoped routes entirely.

## **6.3 Role-based action guards**

Some actions within the org-scoped dashboard are further restricted by role:

* org\_member cannot access: employees\#new, employees\#create, employees\#destroy, ai\_tools\#toggle\_approved, ai\_tools\#create, reports\#export.

* Add a check\_org\_admin\! method that raises 403 if current\_user.org\_member?. Call it as before\_action on the restricted actions listed above.

* org\_member sees the same dashboard pages but destructive controls (buttons, toggles) are hidden in the view. The controller-level check is the authoritative guard — the view-level hiding is cosmetic only.

# **7\. Rails Application Structure**

## **7.1 Authentication (Devise)**

Devise modules: :database\_authenticatable, :rememberable, :validatable only. Do not add :registerable to Devise — registration is a custom controller (Section 7.2). Do not add :recoverable or :confirmable in MVP.

Devise configuration (config/initializers/devise.rb):

* config.mailer\_sender \= ENV\["MAILER\_FROM"\]

* config.sign\_out\_via \= :delete

* config.navigational\_formats \= \["\*/\*", :html\] — explicitly excludes :turbo\_stream to prevent the well-known Devise \+ Turbo Drive double-render conflict

Known issue: Devise flash messages conflict with Turbo Drive. Fix: add a before\_action in ApplicationController that calls flash.discard if request.format.turbo\_stream?. Alternatively use the devise-hotwire-base gem if it is still maintained at build time. Do not ship without testing flash messages with Turbo Drive enabled.

After sign-out, redirect to the Devise sign-in path, not root.

## **7.2 Organisation self-signup (RegistrationsController)**

URL: GET /signup, POST /signup. This is not a Devise route. Custom controller: app/controllers/registrations\_controller.rb.

GET /signup: renders a form. Fields: Organisation Name (required), Your Name (required), Email (required), Password (required), Password Confirmation (required).

POST /signup — processing order (inside a single database transaction):

4. Build an Organisation with name from params. Generate slug from name.parameterize. If slug is taken, append a 4-character random hex suffix and retry once.

5. Trigger Organisation\#after\_create callback which reads config/ai\_tools\_seed.yml and bulk-inserts ai\_tools for the new org. This happens automatically as part of the transaction.

6. Build a User with role: "org\_admin", organisation: the new org, name/email/password from params.

7. Call organisation.save\! and user.save\! inside the transaction. If either fails, roll back both and re-render the form with errors. The form must show both organisation and user validation errors.

8. On success: call sign\_in(user) (Devise helper). Redirect to root\_path with flash\[:notice\] \= "Welcome to ShieldAI. Your organisation has been created."

The /signup route is publicly accessible (no authentication required). All other non-API routes require authentication.

## **7.3 Routes (complete routes.rb)**

| Rails.application.routes.draw do   \# Devise: sign in \+ sign out only   \# No :registrations, :passwords, or :confirmations   devise\_for :users, skip: \[:registrations, :passwords, :confirmations\]   \# Public self-signup (unauthenticated)   get  "/signup", to: "registrations\#new",    as: :signup   post "/signup", to: "registrations\#create"   \# Org-scoped dashboard (org\_admin \+ org\_member)   root "dashboard\#index"   resources :employees, only: \[:index, :show, :new, :create, :destroy\] do     member { get :more\_events }     member { patch :regenerate\_token }   end   resources :ai\_tools, only: \[:index, :create\] do     member { patch :toggle\_approved }   end   resources :reports, only: \[:index\] do     collection { post :export }   end   \# Super admin namespace (super\_admin only)   namespace :admin do     root "dashboard\#index"     resources :organisations, only: \[:index, :show, :new, :create\]     resources :users,         only: \[:index\]   end   \# Chrome extension API (no session auth, token-based)   namespace :api do     namespace :v1 do       resources :detection\_events, only: \[:create\]     end   end end |
| :---- |

## **7.4 ApplicationController**

* before\_action :authenticate\_user\! — Devise default, applies to all routes

* before\_action :authenticate\_org\_user\! — custom (Section 6.2); skipped by Admin::BaseController and Api::V1::DetectionEventsController

* include Pagy::Backend

* helper\_method :current\_organisation

* around\_action :set\_time\_zone — sets Time.zone \= "UTC" for all requests

## **7.5 Admin namespace**

All Admin:: controllers inherit from Admin::BaseController which enforces: authenticate\_user\! and then raises 403 unless current\_user.super\_admin?. Admin controllers skip authenticate\_org\_user\!.

Admin::DashboardController\#index: total organisations, total employees, total events last 30 days (all orgs), list of all organisations with employee count, event count last 30 days, and created\_at date.

Admin::OrganisationsController:

* index: paginated list of all orgs with stats.

* show: org detail — all employees, recent events, all ai\_tools, all users (org\_admin \+ org\_member) belonging to this org.

* new/create: manually provision a new org. Form fields: Organisation Name, Admin Name, Admin Email, Admin Password. Same transaction logic as self-signup (Section 7.2) — creates org, seeds ai\_tools, creates org\_admin user.

Admin::UsersController\#index: paginated list of all users (all roles, all orgs) with name, email, role, org name, created\_at. No create/destroy in MVP — user management is done per-org by org\_admins.

# **8\. API Endpoint (Chrome Extension)**

## **8.1 Overview**

POST /api/v1/detection\_events. This is the only unauthenticated endpoint. The controller must:

* skip\_before\_action :verify\_authenticity\_token

* skip\_before\_action :authenticate\_user\!

* skip\_before\_action :authenticate\_org\_user\!

## **8.2 Request format (JSON body, Content-Type: application/json)**

| Field | Type / Rules |
| :---- | :---- |
| token | string, required — the employee's extension\_token |
| domain | string, required — matched AI tool domain, e.g. "chat.openai.com" |
| page\_title | string, optional — browser tab title, truncated to 255 chars server-side |
| detected\_at | string, required — ISO 8601 UTC, e.g. "2026-03-06T10:30:00Z" |

## **8.3 Processing logic (in this exact order)**

9. Look up Employee by extension\_token. If not found: return 401 {"error":"invalid token"}.

10. If employee.active is false: return 401 {"error":"invalid token"}. (Do not distinguish between "not found" and "inactive" — both return the same message to avoid enumeration.)

11. Set organisation \= employee.organisation.

12. Look up AiTool by organisation\_id: organisation.id AND domain: params\[:domain\] (exact match, downcased). If not found: return 422 {"error":"unknown domain"}.

13. Parse detected\_at as a UTC datetime. If unparseable or absent, default to Time.current.

14. Create DetectionEvent with: organisation\_id, employee\_id, ai\_tool\_id, page\_title (params\[:page\_title\].to\_s.truncate(255)), detected\_at.

15. Return 201 {"status":"ok"}.

Do not return event data or employee data in the success response body. The extension does not use it.

## **8.4 Rate limiting (config/initializers/rack\_attack.rb)**

* Per-token: 60 requests per 60 seconds. Key: "api/token/\#{request.params\['token'\]}". On throttle: 429 {"error":"rate limit exceeded"}.

* Per-IP safety net: 300 requests per 5 minutes. On throttle: 429 {"error":"rate limit exceeded"}.

* Add config.filter\_parameters \+= \[:token\] in config/application.rb — tokens must never appear in log files.

# **9\. Employee Management**

Employees are monitored individuals within an organisation. They are not dashboard users. Only org\_admin can create or deactivate them. org\_member can view them but has no write access.

## **9.1 Creating an employee (org\_admin only)**

GET /employees/new — form with fields: Name (required), Email (required), Department (optional).

POST /employees: employee is scoped to current\_organisation automatically. extension\_token is generated before\_create. On success, display the token to the org\_admin exactly once in a highlighted flash message:

| "Employee created. Token: \[full token value\]. Copy it now — this is the only time it will be shown in full." |
| :---- |

The full token is shown only at this moment. Thereafter only the first 8 characters are shown in the UI.

## **9.2 Regenerating a token (org\_admin only)**

PATCH /employees/:id/regenerate\_token: generates a new SecureRandom.urlsafe\_base64(32) extension\_token and saves it, invalidating the previous token immediately. Displays the new token once in a flash message (same format as creation). The employee must update their extension setup.html with the new token.

## **9.3 Deactivating an employee (org\_admin only)**

DELETE /employees/:id: sets employee.active \= false. Does not delete the record or any detection history. The extension\_token stops working immediately (API returns 401 for inactive employees). The employee row remains visible in the dashboard with a "Deactivated" badge.

No reactivation in MVP. If a deactivated employee needs to be re-added, create a new employee record.

## **9.4 Permission enforcement**

The following actions call check\_org\_admin\! as a before\_action: new, create, destroy, regenerate\_token. If current\_user.org\_member?, raise 403 Forbidden. The action must not execute.

# **10\. Dashboard Pages**

All pages server-rendered with Hotwire. No client-side routing. All data loaded in the controller action. All queries scoped to current\_organisation. Style with Tailwind utility classes.

## **10.1 DashboardController\#index — Organisation Overview**

URL: / (root after login).

Stat cards (4, all scoped to current\_organisation):

* Total sessions all time: current\_organisation.detection\_events.count

* Active employees: current\_organisation.employees.where(active: true).count

* Unique AI tools detected all time: current\_organisation.detection\_events.select(:ai\_tool\_id).distinct.count

* Sessions today: current\_organisation.detection\_events.where(detected\_at: Date.today.all\_day).count

Charts (Chartkick, last 30 days, scoped to current\_organisation):

* Top AI tools: bar chart. Group by ai\_tool.name, count events. Top 10 only.

* Sessions over time: line chart. Group by day using Groupdate: .group\_by\_day(:detected\_at).count

Employee risk table: all active employees in current\_organisation. Columns: Name, Department, Tools Used (distinct ai\_tool count all time), Sessions last 30d, Last Seen (most recent detected\_at), Risk Badge. Default sort: Sessions desc. Clicking a row links to /employees/:id.

Risk badge values: HIGH \= red pill, MEDIUM \= amber pill, LOW \= green pill. Derived from Employee\#risk\_level (Section 11.3).

Recent activity feed: last 20 DetectionEvents in current\_organisation ordered by detected\_at desc. Each row: employee name, tool emoji \+ name, time\_ago\_in\_words. Use includes(:employee, :ai\_tool) to avoid N+1.

## **10.2 EmployeesController\#index**

URL: /employees.

* Search: params\[:search\] — case-insensitive ILIKE on name OR email within current\_organisation.

* Filter by department: params\[:department\] — exact match. Dropdown populated from current\_organisation.employees.distinct.pluck(:department).compact.sort.

* Filter by status: params\[:status\] — "active" (default, shows active: true only) or "all".

* Sort: params\[:sort\] — "sessions" (default, 30d count desc) or "last\_seen" (most recent detected\_at desc).

* Pagination: Pagy at 25 records per page.

* Columns: Name, Email, Department, Sessions last 30d, Last Seen, Risk Badge, Status badge.

* "Add Employee" button: visible and functional for org\_admin only. Hidden for org\_member.

## **10.3 EmployeesController\#show**

URL: /employees/:id. Look up with current\_organisation.employees.find(params\[:id\]).

Header card: name, email, department, avatar initials (first letter of first \+ last name in a coloured circle div). Stat strip: Total Sessions (all time), Tools Used (distinct ai\_tool count), Violations (events on unapproved tools, all time), Avg Daily Sessions last 30d (total events / 30, rounded to 1 decimal).

Risk badge from Employee\#risk\_level.

Activity timeline: loaded in a Turbo Frame (id="activity-timeline"). First load: 20 most recent events ordered by detected\_at desc. "Load more" link at the bottom: navigates the Turbo Frame to GET /employees/:id/more\_events?offset=20. That action returns the next 20 events rendered inside the frame only (not the full layout). Increment offset by 20 per click. Stop showing "Load more" when fewer than 20 events are returned.

Each timeline row: timestamp formatted as "Mar 6, 2026 at 10:30 AM" (strftime "%b %-d, %Y at %l:%M %p"), tool emoji \+ tool name, Approved/Unapproved badge, page\_title truncated to 60 chars in muted text.

Tools used card: detection\_events grouped by ai\_tool, count per tool desc, with Approved/Unapproved badge per tool.

org\_admin only actions (hidden for org\_member): "Regenerate Token" button (PATCH /employees/:id/regenerate\_token), "Deactivate Employee" button (DELETE /employees/:id with confirm dialog).

Back link: "← All Employees" to /employees.

## **10.4 AiToolsController**

URL: /ai\_tools. Scoped to current\_organisation.ai\_tools.

Table columns: Emoji, Name, Domain, Category, Total Sessions all time, Unique Employees, Approved toggle. Sorted by Total Sessions desc. No pagination (max \~36 tools per org in MVP).

Approved toggle: org\_admin sees a functional toggle control. org\_member sees a static badge (approved/unapproved), not a control.

PATCH /ai\_tools/:id/toggle\_approved (org\_admin only): flips approved boolean on the scoped tool. Responds with a Turbo Stream that replaces the specific table row. No full page reload.

"Add Tool" button (org\_admin only): opens a Turbo Frame modal rendered inside a \<dialog\> element. Form fields: Name (required), Domain (required), Category (select from CATEGORIES list), Approved (checkbox, default unchecked). POST /ai\_tools scoped to current\_organisation. On success: close modal, Turbo Stream prepends new row, flash notice. On validation failure: re-render modal with errors, do not redirect.

## **10.5 ReportsController\#index**

URL: /reports.

Date range: params\[:start\_date\] and params\[:end\_date\], parsed with Date.parse. Default: 30 days ago to today. On invalid or absent params, silently use the default range.

All queries scoped to current\_organisation.detection\_events.where(detected\_at: start\_date..end\_date).

Charts: sessions per day line chart, top 10 tools bar chart.

Tables: Top 10 tools (Name, Sessions, Unique Employees). Top 10 employees (Name, Department, Sessions).

Export button (org\_admin only, hidden for org\_member): POST /reports/export with start\_date and end\_date params. Enqueues CsvExportJob.perform\_later(current\_user.id, current\_organisation.id, start\_date.to\_s, end\_date.to\_s). Redirects to /reports with flash\[:notice\] \= "Your report is being generated and will be emailed to \#{current\_user.email}."

# **11\. Models, Validations & Business Logic**

## **11.1 Organisation**

* has\_many :users, dependent: :destroy

* has\_many :employees, dependent: :destroy

* has\_many :ai\_tools, dependent: :destroy

* has\_many :detection\_events, dependent: :destroy

* has\_many :daily\_summaries, dependent: :destroy

* validates :name, presence: true

* validates :slug, presence: true, uniqueness: true

* before\_validation :generate\_slug, on: :create — uses name.parameterize; appends "-\#{SecureRandom.hex(2)}" if the slug is already taken

* after\_create :seed\_ai\_tools — reads config/ai\_tools\_seed.yml and calls AiTool.insert\_all with organisation\_id: id

## **11.2 User**

* Devise modules: :database\_authenticatable, :rememberable, :validatable

* belongs\_to :organisation, optional: true

* ROLES \= %w\[super\_admin org\_admin org\_member\].freeze

* validates :name, presence: true

* validates :role, inclusion: { in: ROLES }

* validates :organisation, presence: true, unless: \-\> { role \== "super\_admin" }

* Instance methods: super\_admin?, org\_admin?, org\_member? — each returns role \== "the\_value"

## **11.3 Employee**

* belongs\_to :organisation

* has\_many :detection\_events, dependent: :destroy

* has\_many :daily\_summaries, dependent: :destroy

* validates :name, presence: true

* validates :email, presence: true, uniqueness: { scope: :organisation\_id, case\_sensitive: false }

* validates :extension\_token, presence: true, uniqueness: true

* before\_create :generate\_extension\_token — SecureRandom.urlsafe\_base64(32)

**Instance method: risk\_level (memoised)**

Count of DetectionEvents for this employee where associated ai\_tool.approved is false. All-time. No date filter.

* Count \>= 3 → "high"

* Count 1 or 2 → "medium"

* Count 0 → "low"

Memoise: @risk\_level ||= ... to avoid repeated queries when called multiple times in a single request.

## **11.4 AiTool**

* CATEGORIES \= %w\[chat code image search writing other\].freeze

* belongs\_to :organisation

* has\_many :detection\_events

* has\_many :daily\_summaries

* validates :name, presence: true

* validates :domain, presence: true, uniqueness: { scope: :organisation\_id, case\_sensitive: false }

* validates :category, inclusion: { in: CATEGORIES }

* before\_save: self.domain \= domain.downcase.strip

## **11.5 DetectionEvent**

* belongs\_to :organisation

* belongs\_to :employee

* belongs\_to :ai\_tool

* validates :detected\_at, presence: true

* scope :recent, \-\> { order(detected\_at: :desc) }

* scope :today, \-\> { where(detected\_at: Time.current.all\_day) }

* scope :last\_days, \-\>(n) { where(detected\_at: n.days.ago.beginning\_of\_day..) }

* scope :unapproved, \-\> { joins(:ai\_tool).where(ai\_tools: { approved: false }) }

## **11.6 DailySummary**

* belongs\_to :organisation

* belongs\_to :employee

* belongs\_to :ai\_tool

* validates :summary\_date, presence: true

* validates :session\_count, numericality: { greater\_than\_or\_equal\_to: 0 }

# **12\. Seed Data**

## **12.1 config/ai\_tools\_seed.yml**

This YAML file is the global default AI tool list. It is not a database table. It is read by Organisation\#after\_create (via seed\_ai\_tools) to populate each new org's ai\_tools on creation. Store at config/ai\_tools\_seed.yml.

Format: a YAML array where each item has keys: name, domain, category, icon\_emoji. The after\_create callback calls AiTool.insert\_all with these attributes plus organisation\_id and the current timestamp.

| Name | Domain | Category |
| :---- | :---- | :---- |
| ChatGPT | chat.openai.com | chat |
| OpenAI Platform | platform.openai.com | chat |
| Claude | claude.ai | chat |
| Gemini | gemini.google.com | chat |
| Google AI Studio | aistudio.google.com | chat |
| Microsoft Copilot | copilot.microsoft.com | chat |
| Bing Copilot | www.bing.com | chat |
| Poe | poe.com | chat |
| Character.AI | character.ai | chat |
| Mistral Le Chat | chat.mistral.ai | chat |
| Grok (xAI) | grok.com | chat |
| Meta AI | meta.ai | chat |
| Perplexity AI | perplexity.ai | search |
| You.com | you.com | search |
| Phind | phind.com | code |
| Cursor | cursor.sh | code |
| Replit AI | replit.com | code |
| Codeium / Windsurf | codeium.com | code |
| Tabnine | app.tabnine.com | code |
| Bolt.new | bolt.new | code |
| v0 by Vercel | v0.dev | code |
| Midjourney | midjourney.com | image |
| Adobe Firefly | firefly.adobe.com | image |
| Canva AI | canva.com | image |
| Leonardo AI | app.leonardo.ai | image |
| Jasper AI | jasper.ai | writing |
| Copy.ai | copy.ai | writing |
| Writesonic | writesonic.com | writing |
| Grammarly | grammarly.com | writing |
| Notion AI | notion.so | writing |
| Otter.ai | otter.ai | other |
| Runway ML | runwayml.com | other |
| ElevenLabs | elevenlabs.io | other |
| Suno AI | suno.com | other |
| Luma AI | lumalabs.ai | other |

## **12.2 db/seeds.rb**

| \# 1\. Super admin (no organisation) User.find\_or\_create\_by\!(email: ENV.fetch("SEED\_SUPER\_ADMIN\_EMAIL")) do |u|   u.name     \= "Super Admin"   u.role     \= "super\_admin"   u.password \= ENV.fetch("SEED\_SUPER\_ADMIN\_PASSWORD") end \# 2\. First test organisation \+ org\_admin \# Organisation\#after\_create seeds ai\_tools automatically. org \= Organisation.find\_or\_create\_by\!(name: ENV.fetch("SEED\_ORG\_NAME")) do |o|   o.active \= true end User.find\_or\_create\_by\!(email: ENV.fetch("SEED\_ORG\_ADMIN\_EMAIL")) do |u|   u.name         \= "Org Admin"   u.role         \= "org\_admin"   u.organisation \= org   u.password     \= ENV.fetch("SEED\_ORG\_ADMIN\_PASSWORD") end |
| :---- |

# **13\. Background Jobs (Solid Queue)**

Solid Queue is configured by default in Rails 8\. Runs as a separate process alongside Puma in production. Configure in Procfile.production.

## **13.1 DailySummaryJob**

Runs nightly at 00:30 UTC. Aggregates the previous calendar day across all organisations.

* Query: DetectionEvent.where(detected\_at: Date.yesterday.all\_day)

* Group by \[organisation\_id, employee\_id, ai\_tool\_id\], count per group

* Upsert into daily\_summaries: DailySummary.upsert\_all(rows, unique\_by: \[:organisation\_id, :employee\_id, :ai\_tool\_id, :summary\_date\], update\_only: \[:session\_count\])

* Log count of orgs and total rows upserted

## **13.2 CsvExportJob**

Arguments: user\_id (integer), organisation\_id (integer), start\_date (string), end\_date (string).

* Fetch User by user\_id and Organisation by organisation\_id. If either missing, log warning and return.

* Query: organisation.detection\_events.includes(:employee, :ai\_tool).where(detected\_at: Date.parse(start\_date)..Date.parse(end\_date)).order(detected\_at: :desc)

* Generate CSV using Ruby stdlib CSV. Columns: Date/Time, Employee Name, Employee Email, Department, AI Tool, Category, Approved (Yes/No).

* Filename: shieldai\_report\_\#{organisation.slug}\_\#{start\_date}\_\#{end\_date}.csv

* Deliver via CsvExportMailer.report(user, csv\_string, filename, start\_date, end\_date).deliver\_now

## **13.3 CleanupJob**

Runs weekly at 02:00 UTC on Sundays.

* DetectionEvent.where("detected\_at \< ?", 90.days.ago).delete\_all

* Log count of deleted records. Do not delete DailySummary records.

## **13.4 config/recurring.yml**

| production:   daily\_summary:     class: DailySummaryJob     schedule: "30 0 \* \* \*"     queue: default   weekly\_cleanup:     class: CleanupJob     schedule: "0 2 \* \* 0"     queue: default |
| :---- |

## **13.5 CsvExportMailer**

app/mailers/csv\_export\_mailer.rb. Single method: report(user, csv\_string, filename, start\_date, end\_date).

To: user.email. From: ENV\["MAILER\_FROM"\]. Subject: "ShieldAI Report: \#{start\_date} to \#{end\_date}". Attach csv\_string with filename: filename, mime\_type: "text/csv".

# **14\. Chrome Extension**

Manifest V3, vanilla JS, zero npm dependencies, no build step. Five files in a folder named shieldai-extension/. The token used here is the employee's extension\_token (not a user login credential).

## **14.1 Files**

| File | Purpose |
| :---- | :---- |
| manifest.json | Extension configuration |
| background.js | Service worker — deduplicates and POSTs events to the API |
| content.js | Content script — detects AI tool domains on every page |
| setup.html | Employee onboarding page for token entry |
| setup.js | JS for setup.html |

## **14.2 manifest.json**

| Key | Value |
| :---- | :---- |
| manifest\_version | 3 |
| name | "ShieldAI" |
| version | "1.0.0" |
| permissions | \["storage"\] |
| host\_permissions | \["\<all\_urls\>"\] |
| background | {"service\_worker":"background.js"} |
| content\_scripts | \[{"matches":\["\<all\_urls\>"\],"js":\["content.js"\],"run\_at":"document\_idle"}\] |
| options\_page | "setup.html" |

## **14.3 content.js**

AI\_DOMAINS: hardcoded array of all 36 domain strings from Section 12.1. Must be kept in sync with config/ai\_tools\_seed.yml manually when new tools are added.

On every page load: iterate AI\_DOMAINS. Check if window.location.hostname \=== domain OR window.location.hostname.endsWith("." \+ domain). On first match, send one message to the background worker and stop iterating. Message: { type: "AI\_TOOL\_DETECTED", domain: matchedDomain, pageTitle: document.title.slice(0, 255), detectedAt: new Date().toISOString() }. No console.log in production.

## **14.4 background.js**

const API\_URL \= "https://REPLACE\_WITH\_SHIELDAI\_HOST/api/v1/detection\_events"; — must be updated to the live SHIELDAI\_HOST before distributing the extension.

On AI\_TOOL\_DETECTED message:

16. Read { token, lastSent } from chrome.storage.local.

17. If token is falsy, return silently.

18. If lastSent\[domain\] exists and Date.now() \- lastSent\[domain\] \< 30 \* 60 \* 1000 (30 min), discard and return.

19. POST to API\_URL with JSON body: { token, domain, page\_title: pageTitle, detected\_at: detectedAt }.

20. On 201 response: set lastSent\[domain\] \= Date.now(), save to chrome.storage.local.

21. On any error (network, 4xx, 5xx): fail silently. No retry. No user-facing error.

## **14.5 setup.html \+ setup.js**

Form: token text input, Activate button, status paragraph, Deactivate button. On load: if token in storage show "ShieldAI is active — token: {first 8 chars}…". On Activate: trim input, if empty show "Please enter a token", else save to storage and show "Activated successfully." On Deactivate: clear token from storage, reload the page.

# **15\. Deployment**

## **15.1 Server requirements**

* Linux VPS — Ubuntu 24.04 LTS or Debian 12\. Minimum 1 vCPU, 2 GB RAM recommended.

* Docker installed on the server (Kamal deploys via Docker containers).

* PostgreSQL 16 on the server or managed (e.g. AWS RDS, Supabase).

* SHIELDAI\_HOST must be DNS-resolvable before running kamal setup.

## **15.2 Procfile.production**

| web:    bundle exec puma \-C config/puma.rb worker: bundle exec rake solid\_queue:start |
| :---- |

## **15.3 config/deploy.yml (Kamal) — required fields**

* service: shieldai

* image: your Docker Hub image name

* servers: the server IP address

* proxy: { host: ENV value of SHIELDAI\_HOST, ssl: true } — Kamal Proxy handles Let's Encrypt SSL automatically

* env.secret: \[DATABASE\_URL, SECRET\_KEY\_BASE, SHIELDAI\_HOST, SMTP\_ADDRESS, SMTP\_PORT, SMTP\_USERNAME, SMTP\_PASSWORD, SMTP\_DOMAIN, MAILER\_FROM, SEED\_SUPER\_ADMIN\_EMAIL, SEED\_SUPER\_ADMIN\_PASSWORD, SEED\_ORG\_NAME, SEED\_ORG\_ADMIN\_EMAIL, SEED\_ORG\_ADMIN\_PASSWORD\]

* Add the Solid Queue worker as an accessory or in the Procfile (Kamal handles multi-process via Procfile.production).

## **15.4 First-run checklist (after kamal setup)**

22. kamal app exec "rails db:migrate"

23. kamal app exec "rails db:seed" — creates super\_admin, first org, first org\_admin, and seeds 36 ai\_tools

24. Open https://SHIELDAI\_HOST, sign in as SEED\_ORG\_ADMIN\_EMAIL, confirm dashboard loads.

25. Sign out. Sign in as SEED\_SUPER\_ADMIN\_EMAIL, confirm /admin dashboard loads.

26. Create 27 employee records via the dashboard (Add Employee form).

27. Export tokens: from the Rails console or by copying each token from the one-time flash on creation.

28. Update API\_URL in background.js to the live SHIELDAI\_HOST. Zip the shieldai-extension/ folder.

29. Distribute extension zip \+ each employee's personal token via 1:1 Slack DM.

30. Employee install: Chrome → chrome://extensions → Enable Developer Mode → Load Unpacked → select folder → click extension icon → Options → paste token → Activate.

31. Verify: have one employee visit chat.openai.com. Within 10 seconds a new event should appear on the dashboard.

# **16\. Recommended Build Order**

Each step is independently testable. Commit before moving to the next.

| Step | Task & acceptance criteria |
| :---- | :---- |
| 1 | rails new \+ Gemfile gems \+ Tailwind \+ Devise (2 modules only) \+ ActionMailer config. Verify: rails server starts, sign-in page renders. |
| 2 | Migrations in order: organisations, users, employees, ai\_tools, detection\_events, daily\_summaries. Verify: schema.rb matches Section 5 exactly. |
| 3 | config/ai\_tools\_seed.yml (36 tools). Organisation model with after\_create seed callback. db/seeds.rb. Run db:seed. Verify in console: 1 super\_admin, 1 org, 1 org\_admin, 36 ai\_tools. |
| 4 | Roles \+ scoping infrastructure: ROLES constant, super\_admin?/org\_admin?/org\_member? methods, authenticate\_org\_user\!, check\_org\_admin\!, current\_organisation helper. Verify: org\_admin can sign in; super\_admin redirected to /admin; org\_member gets 403 on destructive actions. |
| 5 | Public /signup (RegistrationsController). Verify: form creates org \+ org\_admin in one transaction, seeds 36 ai\_tools for the new org, signs in the user, redirects to dashboard. |
| 6 | API endpoint \+ Rack::Attack throttle. Write RSpec request specs: 201 valid token+domain, 401 bad/inactive token, 422 unknown domain, DetectionEvent created with correct organisation\_id. All must pass. |
| 7 | Chrome extension (all 5 files). Load unpacked. Set a seeded employee's token. Visit chat.openai.com. Verify DetectionEvent row in database with correct org/employee/tool. |
| 8 | DashboardController\#index: 4 stat cards \+ 2 Chartkick charts, fully org-scoped. Seed fake events via console to verify charts render. |
| 9 | EmployeesController: index (search/filter/sort/pagination) \+ show (Turbo Frame timeline \+ more\_events) \+ new/create (one-time token flash) \+ destroy (deactivate) \+ regenerate\_token. |
| 10 | AiToolsController: index \+ toggle\_approved (Turbo Stream row update) \+ create (modal). All org-scoped. |
| 11 | ReportsController: index \+ export (CsvExportJob \+ CsvExportMailer). Verify CSV email arrives with correct data. |
| 12 | DailySummaryJob \+ CleanupJob \+ config/recurring.yml. Manually enqueue DailySummaryJob in console. Verify daily\_summaries rows created for all orgs. |
| 13 | Admin namespace: Admin::DashboardController \+ Admin::OrganisationsController (index/show/new/create) \+ Admin::UsersController\#index. Verify super\_admin can provision a new org and the new org gets 36 ai\_tools. |
| 14 | Bullet gem: walk through all pages for each role. Fix every flagged N+1. |
| 15 | Deploy via Kamal. Run first-run checklist (Section 15.4). Confirm end-to-end with a real browser. |

# **17\. Testing Requirements (RSpec)**

The following specs are required before shipping. Do not merge without all passing.

| Spec | What to verify |
| :---- | :---- |
| POST /api/v1/detection\_events | 201 \+ event created for valid token+domain. 401 for unknown token. 401 for inactive employee token. 422 for unknown domain within the org. 429 when throttled. DetectionEvent has correct organisation\_id, employee\_id, ai\_tool\_id, detected\_at. |
| Tenant isolation — employees | Sign in as org\_admin of Org A. GET /employees/:id where :id belongs to Org B. Must return 404\. |
| Tenant isolation — ai\_tools | PATCH /ai\_tools/:id/toggle\_approved where :id belongs to Org B. Must return 404\. |
| Tenant isolation — detection\_events | DashboardController\#index stat cards for Org A must not include events belonging to Org B. |
| RegistrationsController | POST /signup creates Organisation \+ User atomically. On user validation failure, Organisation is not created. ai\_tools seeded for the new org. User has role org\_admin. |
| super\_admin routing | super\_admin hitting GET / is redirected or receives 403\. super\_admin can access GET /admin. |
| org\_admin vs org\_member | org\_member gets 403 on employees\#create, employees\#destroy, ai\_tools\#toggle\_approved, reports\#export. org\_admin succeeds on all of these. |
| Employee\#risk\_level | 0 unapproved events \= low. 1-2 \= medium. 3+ \= high. Approved tool events do not count. Events from other orgs do not count. |
| DailySummaryJob | Populates daily\_summaries for all orgs for yesterday. Upserts correctly on double-run for same date. Does not create rows for today's events. |
| CleanupJob | Deletes events older than 90 days. Events exactly 90 days old are deleted. Events 89 days old are kept. DailySummary records are not deleted. |

# **18\. Security & Privacy Rules**

* Extension records domain name and page title only. No page content, no form values, no keystrokes, no screenshots.

* extension\_token is an employee-level API key. Filter from logs: config.filter\_parameters \+= \[:token\] in application.rb.

* Every org-scoped query must start from current\_organisation. A bare Model.find(id) in a dashboard controller is a security bug.

* HTTPS mandatory in production. config.force\_ssl \= true in config/environments/production.rb.

* CSRF protection on all routes except the API namespace.

* Inactive employees (active: false) cannot post events. API returns 401\.

* DetectionEvents are deleted after 90 days. DailySummary records are kept (counts only, no PII).

* super\_admin can see all organisations' data. This is intentional but must not be used carelessly — display a visible "Super Admin Mode: viewing all organisations" banner in the admin UI.

* The /signup page must have rate limiting: maximum 10 signup attempts per IP per hour via Rack::Attack. Add this to config/initializers/rack\_attack.rb.

# **19\. Post-Launch Roadmap (out of scope for this build)**

| Feature | Architecture note |
| :---- | :---- |
| Billing | Stripe. Add plan and billing\_status columns to organisations. Pricing: \~$5-8/user/month end-customer, \~$3/user/month MSP wholesale. |
| MSP multi-client view | An msp\_accounts table linking MSP users to multiple client organisations. A new msp\_admin role. |
| Email alerts | Trigger when employee risk\_level crosses a threshold. ActionMailer \+ Solid Queue. |
| Org admin password reset | Add Devise :recoverable module. Intentionally excluded from MVP. |
| Blocking AI tools | Requires chrome.declarativeNetRequest in manifest and new Chrome Web Store review. Major extension rewrite. |
| Content inspection (DLP) | MutationObserver on textarea/contenteditable. Requires legal review and explicit employee consent before implementation. |
| Chrome Web Store distribution | Requires developer account, privacy policy URL, and store review. MVP uses Developer Mode (unpacked) install only. |
| Firefox support | MV3 broadly compatible with Firefox 109+. Separate QA pass required. |
| Windows MDM deployment | Group Policy Object plist for Chrome on Windows. Different from Mac Jamf/Kandji approach. |
| Invitation flow for org\_member | Currently org\_admin creates org\_member accounts manually. Future: email invitation link. |

ShieldAI MVP Specification v3.0  —  Multi-Tenant SaaS

*Single source of truth. Follow exactly. When in doubt, ask rather than infer.*
