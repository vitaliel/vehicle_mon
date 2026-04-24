---
stepsCompleted:
  - step-01-init
  - step-02-context
  - step-03-starter
  - step-04-decisions
  - step-05-patterns
  - step-06-structure
  - step-07-validation
  - step-08-complete
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/product-brief-vehicle_mon.md
workflowType: 'architecture'
lastStep: 8
status: 'complete'
completedAt: '2026-04-23'
project_name: 'Vehicle Service Tracker'
user_name: 'Vitalie'
date: '2026-04-23'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
30 FRs across 6 capability areas:
- User Account Management (FR1–FR4): Registration, sign-in, sign-out, account edit
- Vehicle Management (FR5–FR9): CRUD + manual mileage update
- Service Catalog (FR10–FR11): Predefined types, catalog selection on log entry
- Service Log (FR12–FR16): CRUD log entries capturing date, mileage, center, parts/labour cost, notes
- Reminder Thresholds (FR17–FR20): Per-vehicle per-service mileage and/or time thresholds, independently optional
- Due-Soon Calculation (FR21–FR26): Mileage OR time dual-threshold logic; recalculates on new log, mileage update, or threshold change
- Dashboard & Navigation (FR27–FR30): Multi-vehicle dashboard with status indicators, per-vehicle detail view

**Non-Functional Requirements:**
- Performance: <2s initial load; <500ms service save + recalculation; <1s dashboard (10 vehicles)
- Security: All user data strictly scoped per authenticated user; bcrypt passwords; HTTPS; session invalidation on sign-out
- Accessibility: WCAG 2.1 Level A; labeled inputs; keyboard navigation; sufficient color contrast

**Scale & Complexity:**
- Primary domain: Full-stack Rails MPA (server-rendered, no SPA)
- Complexity level: Low — greenfield, single-user-per-account, synchronous calculation, no integrations
- Estimated core models: User, Vehicle, ServiceType, ServiceLogEntry, ReminderThreshold
- Estimated controllers: Dashboard, Vehicles, ServiceLogEntries, ReminderThresholds, Devise (Sessions/Registrations)

### Technical Constraints & Dependencies

- **Framework:** Ruby on Rails 7+ with Turbo — request/response MPA, no SPA framework
- **Database:** PostgreSQL
- **Authentication:** Devise (mandated — no hand-rolled auth)
- **Reminder calculation:** Synchronous on page load — no background job queue for v1
- **Responsive:** Mobile-first CSS; breakpoints 768px (tablet), 1024px (desktop); min viewport 375px; touch targets ≥44px
- **Browser support:** Chrome, Firefox, Safari, Edge — last 2 major versions each

### Cross-Cutting Concerns Identified

1. **User data scoping** — every model association must enforce current_user ownership; no cross-user data access at any layer
2. **Due-soon calculation logic** — triggered by 3 distinct events (log create/edit, mileage update, threshold change); must be encapsulated in a single service/concern to avoid duplication and divergence
3. **Authentication enforcement** — all routes except registration and sign-in require authentication; before_action :authenticate_user! applied globally with explicit exceptions
4. **Responsive layout** — mobile-first design affects view structure and form layout throughout the application

## Starter Template Evaluation

### Primary Technology Domain

Full-stack Ruby on Rails MPA — server-rendered, no SPA framework, responsive via CSS.
All stack decisions are explicitly defined in the PRD; no options needed to evaluate.

### Starter Selected: `rails new` (Rails 8.1.3)

**Rationale:** The PRD explicitly mandates Ruby on Rails with PostgreSQL. Rails 8.1 is the current LTS-aligned release with built-in Turbo, Hotwire, and importmap — all aligned with the no-SPA-framework requirement. No third-party boilerplate is needed or appropriate; `rails new` with the correct flags is the correct foundation.

**Initialization Command:**

```bash
rails new vehicle_mon \
  --database=postgresql \
  --asset-pipeline=propshaft \
  --skip-test \
  --skip-jbuilder
```

**Flags rationale:**
- `--database=postgresql` — mandated by PRD
- `--asset-pipeline=propshaft` — Rails 8 recommended, simpler than Sprockets for new apps
- `--skip-test` — project will use RSpec (added via Gemfile); Rails default minitest skipped
- `--skip-jbuilder` — no JSON API needed; server-rendered views only

**Post-init Gemfile additions:**
```ruby
gem 'devise', '~> 5.0'       # mandated auth solution
gem 'rspec-rails'             # test framework
gem 'factory_bot_rails'       # test factories
gem 'shoulda-matchers'        # model spec matchers
```

### Architectural Decisions Provided by Starter

**Language & Runtime:**
Ruby 3.2+ with Rails 8.1.3. No TypeScript — ERB server-rendered views.

**Styling Solution:**
Plain CSS with mobile-first approach. No Tailwind or component library mandated — keeps the stack minimal and appropriate for household-scale complexity. CSS custom properties for theming; breakpoints at 768px and 1024px.

**Build Tooling:**
Propshaft (asset pipeline) + Importmap for JS. No Node.js build step required. Turbo (Hotwire) included for lightweight page transitions without a JS framework.

**Testing Framework:**
RSpec + FactoryBot + Shoulda Matchers. Minitest skipped at init. RSpec chosen for expressiveness in unit-testing the due-soon calculation domain logic.

**Code Organization:**
Standard Rails MVC convention:
- `app/models/` — domain models + due-soon calculation logic
- `app/controllers/` — thin controllers, auth scoping via before_action
- `app/views/` — ERB templates, partials for vehicle cards and service entries
- `app/services/` (added manually) — DueSoonCalculator service object

**Development Experience:**
- `bin/dev` — starts Rails server and asset watcher
- `bin/rails console` — REPL for domain logic exploration
- Spring not needed (Rails 8 default boot time is fast)

**Note:** Project initialization using this command should be the first implementation story.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- Data model ownership scoping (user → vehicle → log/threshold chain)
- Due-soon calculator encapsulation as a service object
- Authentication via Devise with association-scoped authorization

**Important Decisions (Shape Architecture):**
- Global seeded ServiceType catalog
- Bootstrap 5.3.8 via CDN for responsive UI
- Kamal for self-hosted deployment

**Deferred Decisions (Post-MVP):**
- Custom user-owned service types (Phase 2) — extend ServiceType with nullable user_id
- Email/push notifications (Phase 2) — Action Mailer + background job queue

### Data Architecture

- **ORM:** Rails ActiveRecord with PostgreSQL
- **Migration approach:** Rails migrations (no manual SQL schema changes)
- **Ownership chain:** `users → vehicles → service_log_entries / reminder_thresholds`
- **ServiceType table:** Global, seeded (no user_id). Minimum 6 seed records: engine oil, spark plugs, air filter, brake pads, transmission fluid, tires. Phase 2 adds nullable `user_id` for custom types.
- **ReminderThreshold table:** Scoped by `vehicle_id + service_type_id` (unique index). Row existence = threshold configured; absence = no reminder (FR19 graceful state).
- **Caching:** None for v1 — synchronous calculation on page load is sufficient at household scale (<500 log entries per vehicle NFR)
- **Data validation:** Model-layer validations (presence, numericality, uniqueness); no separate validation service

Schema key decisions:
```
vehicles: id, user_id, make, model, year, current_mileage
service_types: id, name (global, seeded)
service_log_entries: id, vehicle_id, service_type_id, serviced_on, mileage_at_service, service_center, parts_cost, labour_cost, notes
reminder_thresholds: id, vehicle_id, service_type_id, mileage_interval, time_interval_months
```
Unique index: `reminder_thresholds(vehicle_id, service_type_id)`

### Authentication & Security

- **Auth gem:** Devise 5.0.3 — handles registration, sessions, bcrypt password hashing, session invalidation on sign-out
- **Authorization pattern:** Association-scoped queries — `current_user.vehicles.find(params[:id])` everywhere. No policy gem (no roles, no sharing in v1).
- **Global auth enforcement:** `before_action :authenticate_user!` in `ApplicationController`; Devise controllers exempted automatically
- **Data scoping rule:** No bare `Vehicle.find` or `ServiceLogEntry.find` — always scoped through `current_user` association chain
- **HTTPS:** Enforced at infrastructure/reverse proxy level (Nginx); `config.force_ssl = true` in production

### API & Communication Patterns

- **Pattern:** Pure Rails MPA — no JSON API, no GraphQL, no external API surface for v1
- **Routing:** Standard Rails `resources` REST routing for all controllers
- **UI interactions:** Turbo Drive (page transitions) + Turbo Frames (inline updates) for form submissions without full reloads
- **Error handling:** Rails flash messages for user-facing errors; standard 404/422/500 error pages
- **No rate limiting needed** for v1 (no public API, authenticated users only)

### Frontend Architecture

- **Templating:** ERB (Rails default) — no ViewComponent for v1
- **CSS framework:** Bootstrap 5.3.8 loaded via CDN `<link>` tag in application layout — no Node/Yarn build step
- **Responsive strategy:** Bootstrap grid + responsive utilities; mobile-first; all core actions usable at 375px; touch targets ≥44px
- **JavaScript:** Importmap + Turbo (Hotwire). No custom JS framework. Minimal Stimulus controllers only if needed for specific interactions (e.g., dynamic mileage field updates)
- **Icons:** Bootstrap Icons (CDN) for status indicators (due-soon badges)

### Infrastructure & Deployment

- **Deployment tool:** Kamal 2 (included in Rails 8) — Docker-based deployment to VPS
- **Reverse proxy:** Nginx (Kamal manages via `kamal-proxy`)
- **Database:** PostgreSQL on same VPS or managed instance
- **Environment config:** Rails credentials (`config/credentials.yml.enc`) for secrets; `.env` not used in production
- **Logging:** Rails default logger → file; no external logging service for v1
- **CI:** GitHub Actions — run RSpec on push; Kamal deploy on merge to main (optional, can be manual)

### Decision Impact Analysis

**Implementation Sequence:**
1. `rails new` initialization + Gemfile setup
2. Devise installation + User model
3. Core models + migrations (Vehicle, ServiceType seed, ServiceLogEntry, ReminderThreshold)
4. DueSoonCalculator service object (central domain logic)
5. Controllers (Dashboard, Vehicles, ServiceLogEntries, ReminderThresholds) with association scoping
6. Views + Bootstrap layout
7. Kamal deployment configuration

**Cross-Component Dependencies:**
- DueSoonCalculator depends on: ReminderThreshold, ServiceLogEntry, Vehicle (current_mileage)
- All controllers depend on: Devise authentication + current_user association scoping
- Dashboard depends on: DueSoonCalculator results per vehicle per service type

## Implementation Patterns & Consistency Rules

### Pattern Categories Defined

**Critical Conflict Points Identified:** 6 areas where AI agents could make different choices — naming, routing, service interface, error handling, flash keys, and test structure.

### Naming Patterns

**Database Naming Conventions:**
- Tables: `snake_case` plural — `vehicles`, `service_types`, `service_log_entries`, `reminder_thresholds`
- Columns: `snake_case` — `mileage_at_service`, `parts_cost`, `labour_cost`, `time_interval_months`
- Foreign keys: `{model}_id` — `vehicle_id`, `service_type_id`, `user_id`
- Indexes: Rails default (`index_{table}_on_{column}`) — no custom naming

**Controller Naming:**
- `VehiclesController` — vehicle CRUD + mileage update
- `ServiceLogEntriesController` — log entry CRUD, nested under vehicles
- `ReminderThresholdsController` — threshold CRUD, nested under vehicles
- `DashboardController` — single `index` action, no resourceful routing

**Service Object Naming:**
- `DueSoonCalculator` — the single due-soon calculation service (`app/services/due_soon_calculator.rb`)
- No other service objects in v1

**View Partial Naming:**
- `app/views/shared/_vehicle_card.html.erb` — vehicle summary card (used on dashboard + index)
- `app/views/shared/_flash_messages.html.erb` — flash display partial
- Resource-specific partials: `_form.html.erb` within each resource's view folder

**CSS Class Naming:**
- Follow Bootstrap conventions; custom classes use `kebab-case`
- Status indicator classes: `badge-due-soon`, `badge-ok`, `badge-unconfigured`

### Structure Patterns

**Route Organization:**
```ruby
# Full nested routes — no shallow nesting
resources :vehicles do
  resources :service_log_entries
  resources :reminder_thresholds
  member do
    patch :update_mileage
  end
end
root to: 'dashboard#index'
```
URLs follow pattern: `/vehicles/:vehicle_id/service_log_entries/:id`

**Project Organization:**
```
app/
  controllers/
    application_controller.rb      # authenticate_user! + RecordNotFound rescue
    dashboard_controller.rb
    vehicles_controller.rb
    service_log_entries_controller.rb
    reminder_thresholds_controller.rb
  models/
    user.rb
    vehicle.rb
    service_type.rb
    service_log_entry.rb
    reminder_threshold.rb
  services/
    due_soon_calculator.rb         # ONLY service object in v1
  views/
    layouts/application.html.erb
    shared/
      _vehicle_card.html.erb
      _flash_messages.html.erb
    dashboard/index.html.erb
    vehicles/                      # index, show, new, edit, _form
    service_log_entries/           # index, show, new, edit, _form
    reminder_thresholds/           # index, new, edit, _form
spec/
  models/
  controllers/
  services/                        # DueSoonCalculator unit tests live here
  system/                          # end-to-end Capybara tests
  factories/
  support/
```

### Service Interface Pattern

**DueSoonCalculator — canonical interface (agents MUST use this):**
```ruby
result = DueSoonCalculator.call(vehicle: vehicle, service_type: service_type)

# Return value (always a Hash):
# {
#   status: :due_soon | :ok | :unconfigured,
#   mileage_remaining: Integer | nil,   # nil if no mileage threshold
#   days_remaining: Integer | nil       # nil if no time threshold
# }
```
- `:unconfigured` — no ReminderThreshold row exists for this vehicle+service_type
- `:due_soon` — either mileage_remaining <= 0 OR days_remaining <= 0
- `:ok` — both thresholds exist and neither is breached
- Called from: Dashboard controller, Vehicles#show controller — never from views

### Format Patterns

**Flash Messages:**
- Success: `flash[:notice]` only — never `:success` or `:info`
- Error/warning: `flash[:alert]` only — never `:error` or `:danger`
- One flash per action — no stacking multiple messages

**Date/Time:**
- Store: `date` column type for `serviced_on` (no time component needed)
- Display: `strftime('%d %b %Y')` — e.g. "23 Apr 2026"
- Forms: `date_field` helper (HTML5 date input)

**Cost fields:**
- Store: `decimal(10, 2)` in PostgreSQL
- Display: `number_to_currency` helper with locale
- Forms: `number_field` with `step: 0.01, min: 0`

**Mileage fields:**
- Store: `integer` (whole numbers only)
- Display: `number_with_delimiter` helper — e.g. "92,400 km"

### Process Patterns

**Authentication enforcement:**
```ruby
# ApplicationController — applies to ALL controllers
before_action :authenticate_user!
```
Devise registration/sessions controllers are automatically exempted.

**Ownership scoping — MANDATORY pattern:**
```ruby
# CORRECT — always scope through current_user
@vehicle = current_user.vehicles.find(params[:vehicle_id])
@entry = @vehicle.service_log_entries.find(params[:id])

# FORBIDDEN — never use bare finders
@vehicle = Vehicle.find(params[:id])  # ❌
```

**Validation error rendering (Turbo-compatible):**
```ruby
# On failed save — always include unprocessable_entity status
render :new, status: :unprocessable_entity
render :edit, status: :unprocessable_entity
```

**RecordNotFound handling:**
```ruby
# ApplicationController — catch wrong-user access gracefully
rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

def handle_not_found
  redirect_to root_path, alert: "Record not found."
end
```

### Enforcement Guidelines

**All AI Agents MUST:**
- Scope every query through `current_user` association chain — no bare model finders
- Call `DueSoonCalculator.call(vehicle:, service_type:)` — never reimplement calculation logic inline
- Use `flash[:notice]` / `flash[:alert]` exclusively — no other flash keys
- Render with `status: :unprocessable_entity` on validation failures
- Use full nested routes (`/vehicles/:vehicle_id/service_log_entries`) — no shallow variants
- Never put business logic in views — DueSoonCalculator results passed as instance variables from controller

**Anti-Patterns:**
- ❌ `Vehicle.find(params[:id])` — always `current_user.vehicles.find(...)`
- ❌ Inline due-soon calculation in controllers or views — always delegate to `DueSoonCalculator`
- ❌ `flash[:success]` or `flash[:error]` — only `notice` and `alert`
- ❌ `render :new` without `status: :unprocessable_entity` — breaks Turbo form error display
- ❌ Due-soon logic scattered across model callbacks — all calculation in `DueSoonCalculator`

## Project Structure & Boundaries

### Complete Project Directory Structure

```
vehicle_mon/
├── .github/
│   └── workflows/
│       └── ci.yml                      # RSpec on push
├── app/
│   ├── assets/
│   │   └── stylesheets/
│   │       ├── application.css         # Imports + CSS custom properties
│   │       ├── _variables.css          # Colour tokens, breakpoints
│   │       ├── _layout.css             # Page layout, nav, containers
│   │       └── _components.css         # Badges, cards, form overrides
│   ├── controllers/
│   │   ├── application_controller.rb   # authenticate_user!, RecordNotFound rescue
│   │   ├── dashboard_controller.rb     # index — FR27–FR30
│   │   ├── vehicles_controller.rb      # CRUD + update_mileage — FR5–FR9
│   │   ├── service_log_entries_controller.rb  # CRUD — FR12–FR16
│   │   └── reminder_thresholds_controller.rb  # CRUD — FR17–FR20
│   ├── models/
│   │   ├── user.rb                     # FR1–FR4; has_many :vehicles
│   │   ├── vehicle.rb                  # FR5–FR9; belongs_to :user
│   │   ├── service_type.rb             # FR10–FR11; global seed data
│   │   ├── service_log_entry.rb        # FR12–FR16; belongs_to :vehicle, :service_type
│   │   └── reminder_threshold.rb       # FR17–FR20; belongs_to :vehicle, :service_type
│   ├── services/
│   │   └── due_soon_calculator.rb      # FR21–FR26; sole calculation authority
│   └── views/
│       ├── layouts/
│       │   └── application.html.erb    # Bootstrap 5 CDN, Bootstrap Icons CDN, flash partial
│       ├── shared/
│       │   ├── _flash_messages.html.erb
│       │   └── _vehicle_card.html.erb  # Used on dashboard + vehicles#index
│       ├── dashboard/
│       │   └── index.html.erb          # Multi-vehicle grid — FR27, FR28
│       ├── vehicles/
│       │   ├── index.html.erb
│       │   ├── show.html.erb           # Per-vehicle history + due-soon per service — FR29, FR30
│       │   ├── new.html.erb
│       │   ├── edit.html.erb
│       │   └── _form.html.erb
│       ├── service_log_entries/
│       │   ├── index.html.erb          # Chronological history — FR16
│       │   ├── show.html.erb
│       │   ├── new.html.erb
│       │   ├── edit.html.erb
│       │   └── _form.html.erb          # date_field, number_field for mileage/cost
│       └── reminder_thresholds/
│           ├── index.html.erb
│           ├── new.html.erb
│           ├── edit.html.erb
│           └── _form.html.erb
├── config/
│   ├── credentials.yml.enc             # Production secrets (database_url, secret_key_base)
│   ├── database.yml
│   ├── routes.rb                       # Nested resources as defined in patterns
│   └── environments/
│       ├── development.rb
│       └── production.rb               # force_ssl = true
├── db/
│   ├── migrate/
│   │   ├── YYYYMMDD_devise_create_users.rb
│   │   ├── YYYYMMDD_create_vehicles.rb
│   │   ├── YYYYMMDD_create_service_types.rb
│   │   ├── YYYYMMDD_create_service_log_entries.rb
│   │   └── YYYYMMDD_create_reminder_thresholds.rb
│   ├── schema.rb
│   └── seeds.rb                        # 6 global ServiceType records
├── spec/
│   ├── rails_helper.rb
│   ├── spec_helper.rb
│   ├── factories/
│   │   ├── users.rb
│   │   ├── vehicles.rb
│   │   ├── service_types.rb
│   │   ├── service_log_entries.rb
│   │   └── reminder_thresholds.rb
│   ├── models/
│   │   ├── user_spec.rb
│   │   ├── vehicle_spec.rb
│   │   ├── service_log_entry_spec.rb
│   │   └── reminder_threshold_spec.rb
│   ├── services/
│   │   └── due_soon_calculator_spec.rb # Core domain logic tests — all FR21–FR26 edge cases
│   ├── controllers/
│   │   ├── dashboard_controller_spec.rb
│   │   ├── vehicles_controller_spec.rb
│   │   ├── service_log_entries_controller_spec.rb
│   │   └── reminder_thresholds_controller_spec.rb
│   ├── system/
│   │   ├── onboarding_spec.rb          # Journey 1: Marcus first-time setup
│   │   ├── monthly_checkin_spec.rb     # Journey 2: Elena multi-vehicle check
│   │   └── log_entry_spec.rb           # Journey 3: Marcus post-visit log
│   └── support/
│       ├── factory_bot.rb
│       ├── shoulda_matchers.rb
│       └── devise.rb
├── config.ru
├── Gemfile
├── Gemfile.lock
├── Dockerfile                          # Generated by rails new; used by Kamal
├── .kamal/
│   └── deploy.yml                      # Kamal deployment config
└── README.md
```

### Architectural Boundaries

**Authentication Boundary:**
- Entry point: Devise routes (`/users/sign_in`, `/users/sign_up`, `/users/sign_out`)
- Enforcement: `ApplicationController#before_action :authenticate_user!`
- Scope: All controllers inherit; Devise controllers auto-exempt

**Ownership Boundary:**
- All data access starts at `current_user` — never bypassed
- Chain: `current_user → .vehicles → .service_log_entries / .reminder_thresholds`
- Violation protection: `rescue_from ActiveRecord::RecordNotFound` in ApplicationController

**Calculation Boundary:**
- `DueSoonCalculator` is the sole authority for due-soon status
- Input: `vehicle` + `service_type` ActiveRecord objects
- Output: `{ status:, mileage_remaining:, days_remaining: }` hash
- Consumers: `DashboardController`, `VehiclesController#show` only

**Data Boundary:**
- No direct SQL; all access via ActiveRecord
- No cross-user joins; all queries scoped via association chain
- Global data: `ServiceType` (read-only in v1, no user scoping)

### Requirements to Structure Mapping

| FR Category | Controller | Model(s) | Views |
|---|---|---|---|
| User Account (FR1–FR4) | Devise (auto) | `User` | Devise default views |
| Vehicle Management (FR5–FR9) | `VehiclesController` | `Vehicle` | `vehicles/` |
| Service Catalog (FR10–FR11) | — (seed data) | `ServiceType` | `_form` select fields |
| Service Log (FR12–FR16) | `ServiceLogEntriesController` | `ServiceLogEntry` | `service_log_entries/` |
| Thresholds (FR17–FR20) | `ReminderThresholdsController` | `ReminderThreshold` | `reminder_thresholds/` |
| Due-Soon Calc (FR21–FR26) | — | — | `DueSoonCalculator` service |
| Dashboard (FR27–FR30) | `DashboardController` | (reads all) | `dashboard/index` |

**Cross-Cutting Concern Locations:**
- Authentication: `ApplicationController` + Devise
- Due-soon logic: `app/services/due_soon_calculator.rb` exclusively
- Flash rendering: `app/views/shared/_flash_messages.html.erb`
- Bootstrap + icons: `app/views/layouts/application.html.erb` CDN tags

### Data Flow

**Dashboard load (FR27–FR28):**
```
Request → authenticate_user! → DashboardController#index
  → current_user.vehicles.includes(:service_log_entries, :reminder_thresholds)
  → DueSoonCalculator.call(vehicle:, service_type:) per vehicle×service_type
  → @vehicle_summaries assigned → dashboard/index.html.erb rendered
```

**New service log entry (FR12, FR23):**
```
POST /vehicles/:vehicle_id/service_log_entries
  → authenticate_user! → find vehicle via current_user
  → ServiceLogEntry.create → on success → redirect to vehicle show
  → vehicle show recalculates due-soon via DueSoonCalculator for all service types
```

**Mileage update (FR8, FR24):**
```
PATCH /vehicles/:id/update_mileage
  → authenticate_user! → current_user.vehicles.find
  → vehicle.update(current_mileage:) → redirect to vehicle show
  → vehicle show recalculates due-soon via DueSoonCalculator
```

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:**
All technology choices are mutually compatible: Rails 8.1.3 ships with Turbo, Propshaft,
Importmap, and Kamal 2 as defaults. Bootstrap 5 via CDN requires no build tooling.
Devise 5.0.3 is Rails 8 compatible. RSpec + FactoryBot is the standard Rails test stack.

**Pattern Consistency:**
Nested routes, DueSoonCalculator interface, ownership scoping pattern, and flash key
conventions are defined once and referenced consistently throughout all sections.

**Structure Alignment:**
Every controller has a corresponding view directory. Every model has a factory.
Every FR category maps to exactly one controller+model+view group. The single
`app/services/` object is isolated and scoped correctly.

### Requirements Coverage Validation ✅

All 30 FRs are architecturally supported:
- FR1–FR4: Devise + User model
- FR5–FR9: VehiclesController + Vehicle model (includes update_mileage member action)
- FR10–FR11: Global ServiceType seed data + select helper in _form partials
- FR12–FR16: ServiceLogEntriesController nested under vehicles
- FR17–FR20: ReminderThresholdsController + unique index on (vehicle_id, service_type_id)
- FR21–FR26: DueSoonCalculator sole authority; all 4 threshold states handled (:ok, :due_soon, :unconfigured)
- FR27–FR30: DashboardController + VehiclesController#show

**NFR Coverage:**
- Performance: Eager loading `includes(:service_log_entries, :reminder_thresholds)` on
  dashboard query prevents N+1; synchronous calculation stays within <500ms at household scale
- Security: Association-scoped queries + RecordNotFound rescue + force_ssl in production
- Accessibility: Bootstrap accessible components + semantic form helpers with labels
- Responsive: Bootstrap grid, mobile-first, 375px minimum viewport

### Gap Analysis Results

**No critical gaps identified.**

**Minor gap addressed:** Dashboard query must eager-load both `service_log_entries` and
`reminder_thresholds` to prevent N+1 queries when DueSoonCalculator iterates service types.
Resolved: documented explicitly in Data Flow section and enforced as a controller pattern.

### Architecture Completeness Checklist

**✅ Requirements Analysis**
- [x] Project context thoroughly analyzed (30 FRs, 4 NFR categories)
- [x] Scale and complexity assessed (Low — household, synchronous, no integrations)
- [x] Technical constraints identified (Rails 8, PostgreSQL, Devise, Turbo, no SPA)
- [x] Cross-cutting concerns mapped (auth scoping, due-soon calc, responsive layout)

**✅ Architectural Decisions**
- [x] Critical decisions documented with verified versions
- [x] Technology stack fully specified (Rails 8.1.3, Bootstrap 5.3.8, Devise 5.0.3)
- [x] Integration patterns defined (MPA + Turbo, no API layer)
- [x] Performance considerations addressed (eager loading, synchronous calc)

**✅ Implementation Patterns**
- [x] Naming conventions established (controllers, service, partials, CSS classes)
- [x] Structure patterns defined (full nested routes, RSpec folders)
- [x] Service interface specified (DueSoonCalculator.call canonical signature)
- [x] Process patterns documented (auth, ownership scoping, flash keys, Turbo render)

**✅ Project Structure**
- [x] Complete directory structure defined with file-level specificity
- [x] Component boundaries established (auth, ownership, calculation, data)
- [x] Integration points mapped (data flow for 3 key operations)
- [x] All FRs mapped to specific files and directories

### Architecture Readiness Assessment

**Overall Status:** READY FOR IMPLEMENTATION
**Confidence Level:** High

**Key Strengths:**
- DueSoonCalculator boundary prevents the most likely source of divergence across agents
- Ownership scoping pattern is simple and enforceable — one rule, applied everywhere
- Full nested routes eliminate ambiguity about URL structure for nested resources
- Bootstrap via CDN keeps the stack Node-free and consistent with Propshaft/Importmap

**Areas for Future Enhancement (Post-MVP):**
- Phase 2: Add nullable `user_id` to `service_types` for custom types
- Phase 2: Action Mailer + background job (Solid Queue, Rails 8 default) for email notifications
- Phase 2: `active_storage` for receipt attachments

### Implementation Handoff

**AI Agent Guidelines:**
- Follow all architectural decisions exactly as documented
- Use `DueSoonCalculator.call(vehicle:, service_type:)` — never reimplement inline
- Scope all queries through `current_user` association chain — no bare finders
- Use full nested routes — no shallow routing variants
- Refer to this document for all architectural questions before making independent decisions

**First Implementation Priority:**
```bash
rails new vehicle_mon \
  --database=postgresql \
  --asset-pipeline=propshaft \
  --skip-test \
  --skip-jbuilder
```
