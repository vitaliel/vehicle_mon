---
stepsCompleted:
  - step-01-validate-prerequisites
  - step-02-design-epics
  - step-03-create-stories
  - step-04-final-validation
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
---

# Vehicle Service Tracker - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for Vehicle Service Tracker, decomposing the requirements from the PRD and Architecture into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: Visitors can register a new account with email and password
FR2: Registered users can sign in with email and password
FR3: Authenticated users can sign out
FR4: Authenticated users can view and update their account details
FR5: Authenticated users can add a vehicle with make, model, year, and current mileage
FR6: Authenticated users can edit any of their vehicle's details
FR7: Authenticated users can delete a vehicle and all its associated data
FR8: Authenticated users can update the current mileage of a vehicle at any time
FR9: Authenticated users can view a list of all their registered vehicles
FR10: The system provides a predefined catalog of service types (minimum: engine oil, spark plugs, air filter, brake pads, transmission fluid, tires)
FR11: Users select a service type from the catalog when logging a service entry
FR12: Authenticated users can create a service log entry for a vehicle, selecting a service type from the catalog
FR13: A service log entry captures: date, mileage at service, service center name, parts cost, labour cost, and optional notes
FR14: Authenticated users can edit an existing service log entry
FR15: Authenticated users can delete a service log entry
FR16: Authenticated users can view all service log entries for a vehicle in chronological order
FR17: Authenticated users can configure a mileage threshold for a specific service type on a specific vehicle
FR18: Authenticated users can configure a time (calendar) threshold for a specific service type on a specific vehicle
FR19: Both thresholds are optional — a service type with no threshold configured shows no reminder
FR20: Thresholds are independent per vehicle and per service type
FR21: The system calculates due-soon status per service type per vehicle, based on the last logged entry and configured thresholds
FR22: Due-soon calculation uses mileage OR time, whichever threshold is reached first
FR23: The system recalculates due-soon status when a new service entry is logged
FR24: The system recalculates due-soon status when a vehicle's current mileage is updated
FR25: The system recalculates due-soon status when a threshold is changed
FR26: A service type with no logged entries and no thresholds shows a neutral/unconfigured state
FR27: Authenticated users see a dashboard listing all their vehicles
FR28: The dashboard shows a due-soon status indicator per vehicle
FR29: Authenticated users can navigate to a per-vehicle detail view showing service history and reminder status
FR30: The per-vehicle view shows due-soon status per service type with estimated mileage or time remaining

### NonFunctional Requirements

NFR1: Initial page load < 2s on standard broadband
NFR2: Service log save + due-soon recalculation < 500ms server round-trip
NFR3: Dashboard with up to 10 vehicles < 1s load time
NFR4: Reminder calculation consistent up to 500 log entries per vehicle
NFR5: All user data strictly scoped to the authenticated user — no cross-user data access
NFR6: Passwords stored as bcrypt hashes; never persisted or logged in plaintext
NFR7: All data in transit protected via HTTPS (TLS 1.2+)
NFR8: Session tokens invalidated on sign-out
NFR9: No sensitive data exposed in URLs or application logs
NFR10: WCAG 2.1 Level A for all core user flows
NFR11: All form inputs have associated labels
NFR12: Keyboard navigation works for all primary actions
NFR13: Sufficient colour contrast for due-soon status indicators
NFR14: Responsive layout — all core actions usable on a 375px viewport; touch targets ≥44px
NFR15: Browser support: Chrome, Firefox, Safari, Edge — last 2 major versions each

### Additional Requirements

- ARC1: Project initialization using `rails new vehicle_mon --database=postgresql --asset-pipeline=propshaft --skip-test --skip-jbuilder` — must be the **first** implementation story
- ARC2: Gemfile post-init additions: `devise (~> 5.0)`, `rspec-rails`, `factory_bot_rails`, `shoulda-matchers`
- ARC3: Global ServiceType seed data — 6 records: engine oil, spark plugs, air filter, brake pads, transmission fluid, tires
- ARC4: `DueSoonCalculator` service object as sole calculation authority — interface: `DueSoonCalculator.call(vehicle:, service_type:)` returning `{ status:, mileage_remaining:, days_remaining: }`
- ARC5: All controllers scope queries through `current_user` association chain — no bare model finders permitted
- ARC6: Bootstrap 5.3.8 and Bootstrap Icons loaded via CDN in `application.html.erb`
- ARC7: GitHub Actions CI workflow — RSpec on push (`ci.yml`)
- ARC8: Kamal 2 deployment configuration for Docker-based VPS deployment
- ARC9: `config.force_ssl = true` in production environment
- ARC10: `rescue_from ActiveRecord::RecordNotFound` in ApplicationController — redirect to root with alert
- ARC11: Validation failures render with `status: :unprocessable_entity` for Turbo compatibility

### UX Design Requirements

_No UX Design document provided._

### FR Coverage Map

| FR | Epic | Description |
|---|---|---|
| FR1 | Epic 1 | User registration |
| FR2 | Epic 1 | User sign in |
| FR3 | Epic 1 | User sign out |
| FR4 | Epic 1 | View/update account details |
| FR5 | Epic 2 | Add vehicle |
| FR6 | Epic 2 | Edit vehicle |
| FR7 | Epic 2 | Delete vehicle + cascading data |
| FR8 | Epic 2 | Update current mileage |
| FR9 | Epic 2 | View vehicle list |
| FR10 | Epic 3 | Predefined service catalog |
| FR11 | Epic 3 | Select service type on log entry |
| FR12 | Epic 3 | Create service log entry |
| FR13 | Epic 3 | Log entry fields (date, mileage, center, costs, notes) |
| FR14 | Epic 3 | Edit service log entry |
| FR15 | Epic 3 | Delete service log entry |
| FR16 | Epic 3 | Chronological history view |
| FR17 | Epic 4 | Configure mileage threshold |
| FR18 | Epic 4 | Configure time threshold |
| FR19 | Epic 4 | Optional thresholds — graceful no-threshold state |
| FR20 | Epic 4 | Independent per-vehicle per-service thresholds |
| FR21 | Epic 4 | Calculate due-soon status |
| FR22 | Epic 4 | Mileage OR time (whichever first) |
| FR23 | Epic 4 | Recalculate on new log entry |
| FR24 | Epic 4 | Recalculate on mileage update |
| FR25 | Epic 4 | Recalculate on threshold change |
| FR26 | Epic 4 | Neutral/unconfigured state |
| FR27 | Epic 5 | Multi-vehicle dashboard |
| FR28 | Epic 5 | Dashboard due-soon status indicators |
| FR29 | Epic 5 | Navigate to per-vehicle detail view |
| FR30 | Epic 4 | Per-vehicle view: due-soon per service type with remaining estimate |

## Epic List

### Epic 1: Project Foundation & User Authentication
Users can register, sign in, sign out, and manage their account. The application is initialized with the correct Rails stack, CI, security baseline, and Bootstrap layout — providing the foundation for all future epics.
**FRs covered:** FR1, FR2, FR3, FR4
**ARCs covered:** ARC1, ARC2, ARC6, ARC7, ARC9, ARC10, ARC11

### Epic 2: Vehicle Fleet Management
Authenticated users can add, edit, delete, and view all their vehicles, and update a vehicle's current mileage at any time.
**FRs covered:** FR5, FR6, FR7, FR8, FR9

### Epic 3: Service History Logging
Users can log every service event per vehicle from a predefined catalog with full cost tracking, and view, edit, or delete their complete chronological service history.
**FRs covered:** FR10, FR11, FR12, FR13, FR14, FR15, FR16
**ARCs covered:** ARC3

### Epic 4: Maintenance Reminders & Due-Soon Engine
Users can configure mileage and/or time thresholds per vehicle per service type, and the system automatically calculates and displays due-soon status — recalculating whenever relevant data changes.
**FRs covered:** FR17, FR18, FR19, FR20, FR21, FR22, FR23, FR24, FR25, FR26, FR30
**ARCs covered:** ARC4

### Epic 5: Dashboard & Production Readiness
Users see all their vehicles and due-soon status at a glance on a dashboard and can navigate to any vehicle's detail view. The application is deployed and production-ready via Kamal.
**FRs covered:** FR27, FR28, FR29
**ARCs covered:** ARC5, ARC8

## Epic 1: Project Foundation & User Authentication

Users can register, sign in, sign out, and manage their account. The application is initialized with the correct Rails stack, CI, security baseline, and Bootstrap layout — providing the foundation for all future epics.

### Story 1.1: Rails Application Initialization

As a developer,
I want the Rails 8.1 application initialized with PostgreSQL, Propshaft, RSpec, Devise, and Bootstrap layout,
So that all future stories have a correct, consistent foundation to build on.

**Acceptance Criteria:**

**Given** the repository is cloned
**When** `bin/setup` (or `bundle install && rails db:create`) is run
**Then** the application boots without errors (`rails server` starts successfully)
**And** the database is created in PostgreSQL

**Given** the app is running
**When** any page is requested
**Then** the Bootstrap 5.3.8 layout renders (CDN link present in `<head>`)
**And** a `_flash_messages` shared partial is included in the layout
**And** a `_vehicle_card` shared partial file exists (empty/stubbed for now)

**Given** the Gemfile
**When** reviewed
**Then** it includes `devise (~> 5.0)`, `rspec-rails`, `factory_bot_rails`, `shoulda-matchers`
**And** `--skip-test` was used (no minitest) and `--skip-jbuilder` applied

**Given** the repo
**When** a push is made to any branch
**Then** GitHub Actions CI runs RSpec and reports pass/fail

### Story 1.2: User Registration

As a visitor,
I want to register a new account with email and password,
So that I can access the Vehicle Service Tracker.

**Acceptance Criteria:**

**Given** I am not signed in
**When** I visit `/users/sign_up`
**Then** I see a registration form with email and password fields
**And** all form inputs have visible, associated labels (NFR11)

**Given** I submit valid email and password
**When** the form is submitted
**Then** my account is created and I am signed in
**And** I am redirected to the dashboard (root path)
**And** a `flash[:notice]` confirmation message is shown

**Given** I submit a duplicate email
**When** the form is submitted
**Then** I see a validation error message
**And** the form re-renders with `status: 422` (Turbo-compatible, ARC11)

**Given** I submit with a missing or invalid email
**When** the form is submitted
**Then** I see a specific validation error
**And** my password is never shown in logs or URLs (NFR9)

### Story 1.3: User Sign In & Sign Out

As a registered user,
I want to sign in with my email and password, and sign out when done,
So that my data is secure and only I can access it.

**Acceptance Criteria:**

**Given** I am not signed in
**When** I visit `/users/sign_in` and submit valid credentials
**Then** I am signed in and redirected to the dashboard
**And** a `flash[:notice]` welcome message is shown

**Given** I am not signed in
**When** I visit any protected route
**Then** I am redirected to the sign-in page (all routes protected, NFR5)

**Given** I submit invalid credentials
**When** the sign-in form is submitted
**Then** I see a `flash[:alert]` error message
**And** I remain on the sign-in page

**Given** I am signed in
**When** I sign out
**Then** my session is invalidated (NFR8)
**And** I am redirected to the sign-in page
**And** I cannot access protected routes without signing in again

### Story 1.4: Account Details Management

As an authenticated user,
I want to view and update my account details (email and password),
So that I can keep my login credentials current.

**Acceptance Criteria:**

**Given** I am signed in
**When** I visit my account settings page (`/users/edit`)
**Then** I see a form pre-filled with my current email

**Given** I submit a valid email change
**When** the form is saved
**Then** my email is updated
**And** a `flash[:notice]` confirmation is shown

**Given** I submit a password change with valid current password
**When** the form is saved
**Then** my password is updated and stored as a bcrypt hash (NFR6)
**And** I remain signed in

**Given** I submit a password change with an incorrect current password
**When** the form is submitted
**Then** I see a validation error and the change is rejected

## Epic 2: Vehicle Fleet Management

Authenticated users can add, edit, delete, and view all their vehicles, and update a vehicle's current mileage at any time.

### Story 2.1: Add & List Vehicles

As an authenticated user,
I want to add a vehicle with make, model, year, and current mileage, and view my list of vehicles,
So that I can start tracking maintenance for my cars.

**Acceptance Criteria:**

**Given** I am signed in
**When** I visit the vehicles index page
**Then** I see a list of all my registered vehicles (or an empty state with a prompt to add one)

**Given** I fill in make, model, year, and current mileage and submit
**When** the vehicle is saved
**Then** it appears in my vehicle list
**And** a `flash[:notice]` confirmation is shown
**And** the vehicle is scoped to my account only (other users cannot see it, NFR5/ARC5)

**Given** I submit with a required field missing (e.g., no make)
**When** the form is submitted
**Then** I see a validation error and the form re-renders with `status: 422`

**Given** I am on mobile (375px viewport)
**When** I view or submit the vehicle form
**Then** all inputs and touch targets are usable (NFR14)

### Story 2.2: Edit Vehicle Details

As an authenticated user,
I want to edit any of my vehicle's details,
So that I can correct mistakes or update information.

**Acceptance Criteria:**

**Given** I own a vehicle
**When** I visit its edit page and submit valid changes
**Then** the details are updated and I see a `flash[:notice]` confirmation

**Given** I submit with a required field cleared
**When** the form is submitted
**Then** I see a validation error and the form re-renders with `status: 422`

**Given** another user's vehicle ID is used in the URL
**When** I attempt to access the edit page
**Then** I am redirected to root with a `flash[:alert]` (ARC10 — RecordNotFound handling)

### Story 2.3: Delete Vehicle

As an authenticated user,
I want to delete a vehicle and all its associated data,
So that I can remove a car I no longer own.

**Acceptance Criteria:**

**Given** I own a vehicle with associated service log entries and thresholds
**When** I delete the vehicle
**Then** the vehicle and all its associated records are permanently deleted (cascade)
**And** I am redirected to the vehicles list with a `flash[:notice]` confirmation

**Given** another user's vehicle ID is used in a delete request
**When** the request is processed
**Then** I am redirected to root with a `flash[:alert]` (no cross-user deletion, NFR5)

### Story 2.4: Update Vehicle Mileage

As an authenticated user,
I want to update my vehicle's current mileage at any time,
So that the app always reflects the vehicle's real odometer reading.

**Acceptance Criteria:**

**Given** I am on my vehicle's detail page
**When** I submit a mileage update with a valid integer value
**Then** the vehicle's `current_mileage` is updated
**And** I am redirected back to the vehicle detail page with a `flash[:notice]`

**Given** I submit a non-numeric or negative mileage value
**When** the form is submitted
**Then** I see a validation error and the change is rejected

**Given** another user's vehicle ID is in the URL
**When** the update request is submitted
**Then** I am redirected to root with a `flash[:alert]`

## Epic 3: Service History Logging

Users can log every service event per vehicle from a predefined catalog with full cost tracking, and view, edit, or delete their complete chronological service history.

### Story 3.1: Service Type Catalog Seed

As a developer,
I want the database seeded with the predefined service type catalog,
So that users can select service types when logging entries without any configuration.

**Acceptance Criteria:**

**Given** `rails db:seed` is run
**When** the seeds complete
**Then** exactly 6 service type records exist: Engine Oil, Spark Plugs, Air Filter, Brake Pads, Transmission Fluid, Tires
**And** running `db:seed` again does not create duplicates (idempotent)

**Given** the `ServiceType` model
**When** reviewed
**Then** it has no `user_id` column (global catalog, not user-owned, per architecture)

### Story 3.2: Create Service Log Entry

As an authenticated user,
I want to log a service entry for one of my vehicles by selecting a service type from the catalog,
So that I have a permanent record of every maintenance event.

**Acceptance Criteria:**

**Given** I own a vehicle and service types are seeded
**When** I visit the new service log entry form for my vehicle
**Then** I see a dropdown of all service types (FR11)
**And** all fields have associated labels: date, mileage at service, service center name, parts cost, labour cost, notes (optional) (FR13, NFR11)

**Given** I fill in all required fields and submit
**When** the entry is saved
**Then** it appears in my vehicle's service history
**And** a `flash[:notice]` confirmation is shown
**And** the save completes in under 500ms (NFR2)

**Given** I submit without a required field (date or mileage)
**When** the form is submitted
**Then** I see a validation error and the form re-renders with `status: 422`

**Given** another user's vehicle ID is in the URL
**When** I attempt to access the new entry form
**Then** I am redirected to root with a `flash[:alert]` (ARC5/ARC10)

### Story 3.3: View Service History

As an authenticated user,
I want to view all service log entries for a vehicle in chronological order,
So that I can review the full maintenance history at a glance.

**Acceptance Criteria:**

**Given** I own a vehicle with multiple service log entries
**When** I visit the vehicle's service log index
**Then** entries are listed in chronological order (oldest first) (FR16)
**And** each entry shows: service type, date (formatted as "DD Mon YYYY"), mileage, service center, parts cost, labour cost, notes

**Given** I own a vehicle with no service log entries
**When** I visit its service log index
**Then** I see a friendly empty state with a prompt to add the first entry

**Given** I am on mobile
**When** I view the service history list
**Then** the layout is readable and usable at 375px (NFR14)

### Story 3.4: Edit Service Log Entry

As an authenticated user,
I want to edit an existing service log entry,
So that I can correct mistakes after saving.

**Acceptance Criteria:**

**Given** I own a service log entry
**When** I visit its edit form
**Then** all fields are pre-filled with the current values

**Given** I submit valid changes
**When** the form is saved
**Then** the entry is updated and a `flash[:notice]` confirmation is shown

**Given** I submit with a required field cleared
**When** the form is submitted
**Then** I see a validation error and the form re-renders with `status: 422`

**Given** another user's entry ID is in the URL
**When** I attempt to access the edit page
**Then** I am redirected to root with a `flash[:alert]`

### Story 3.5: Delete Service Log Entry

As an authenticated user,
I want to delete a service log entry,
So that I can remove incorrectly logged records.

**Acceptance Criteria:**

**Given** I own a service log entry
**When** I delete it
**Then** the entry is permanently removed from the database
**And** I am redirected to the service history with a `flash[:notice]` confirmation

**Given** another user's entry ID is used in a delete request
**When** the request is processed
**Then** I am redirected to root with a `flash[:alert]` (NFR5)

## Epic 4: Maintenance Reminders & Due-Soon Engine

Users can configure mileage and/or time thresholds per vehicle per service type, and the system automatically calculates and displays due-soon status — recalculating whenever relevant data changes.

### Story 4.1: DueSoonCalculator Service Object

As a developer,
I want a `DueSoonCalculator` service object that encapsulates all due-soon calculation logic,
So that calculation is consistent, testable, and never duplicated across controllers or views.

**Acceptance Criteria:**

**Given** a vehicle and service type
**When** `DueSoonCalculator.call(vehicle:, service_type:)` is called
**Then** it returns `{ status: :unconfigured, mileage_remaining: nil, days_remaining: nil }` when no `ReminderThreshold` row exists (FR19, FR26)

**Given** a threshold exists and neither limit is breached
**When** `DueSoonCalculator.call` is invoked
**Then** it returns `{ status: :ok, mileage_remaining: Integer, days_remaining: Integer }` (nil for whichever threshold is not configured)

**Given** either the mileage or time threshold is reached or exceeded
**When** `DueSoonCalculator.call` is invoked
**Then** it returns `{ status: :due_soon, ... }` (FR22 — whichever arrives first)

**Given** only a mileage threshold is set (no time threshold)
**When** the calculator is called
**Then** it evaluates mileage only; `days_remaining` is nil

**Given** only a time threshold is set (no mileage threshold)
**When** the calculator is called
**Then** it evaluates time only; `mileage_remaining` is nil

**Given** the `spec/services/due_soon_calculator_spec.rb`
**When** the test suite runs
**Then** all four threshold states (:ok, :due_soon, :unconfigured, and mixed mileage-only / time-only) have passing unit tests

### Story 4.2: Configure Reminder Thresholds

As an authenticated user,
I want to configure mileage and/or time thresholds for a specific service type on a specific vehicle,
So that the system knows when to alert me that maintenance is due.

**Acceptance Criteria:**

**Given** I own a vehicle and service types are seeded
**When** I visit the reminder thresholds page for my vehicle
**Then** I see the list of service types with their current threshold configuration (or "not configured" if none set)

**Given** I set a mileage interval, a time interval (months), or both for a service type and save
**When** the threshold is saved
**Then** a `ReminderThreshold` row exists for that vehicle + service type (FR17, FR18, FR20)
**And** a `flash[:notice]` confirmation is shown

**Given** both mileage and time fields are left blank
**When** I submit
**Then** no threshold row is saved (graceful no-threshold state, FR19)

**Given** another user's vehicle ID is in the URL
**When** I attempt to access thresholds
**Then** I am redirected to root with a `flash[:alert]`

### Story 4.3: Due-Soon Status on Vehicle Detail View

As an authenticated user,
I want to see the due-soon status for every service type on my vehicle's detail page,
So that I know exactly which services are coming up and how much time or mileage I have left.

**Acceptance Criteria:**

**Given** a vehicle has thresholds configured and log entries exist
**When** I visit the vehicle's detail page (`vehicles#show`)
**Then** each service type shows its status badge: `:ok` (green), `:due_soon` (yellow/amber), or `:unconfigured` (neutral) (FR30, NFR13)
**And** `:ok` and `:due_soon` entries display estimated mileage remaining and/or days remaining

**Given** a service type has no threshold configured
**When** I view that service type on the detail page
**Then** it shows a neutral "not configured" state — not an error (FR26)

**Given** the page loads with up to all 6 service types across multiple log entries
**When** the page renders
**Then** it completes in under 500ms (NFR2) by calling `DueSoonCalculator.call` — never reimplementing logic inline (ARC4)

### Story 4.4: Recalculate Due-Soon on Data Changes

As an authenticated user,
I want the due-soon status to update automatically whenever I log a service, update mileage, or change a threshold,
So that the reminders always reflect the current state of my vehicle.

**Acceptance Criteria:**

**Given** I log a new service entry for a vehicle
**When** I am redirected to the vehicle detail page
**Then** the due-soon status for that service type reflects the new log entry (FR23)

**Given** I update a vehicle's current mileage
**When** I am redirected to the vehicle detail page
**Then** the due-soon status for all service types reflects the updated mileage (FR24)

**Given** I change a reminder threshold for a service type
**When** I am redirected to the vehicle detail page
**Then** the due-soon status for that service type reflects the new threshold (FR25)

**Given** all three recalculation triggers
**When** each is exercised in the test suite
**Then** `DueSoonCalculator.call` is the only calculation path invoked — no inline logic in controllers or views (ARC4)

## Epic 5: Dashboard & Production Readiness

Users see all their vehicles and due-soon status at a glance on a dashboard and can navigate to any vehicle's detail view.

### Story 5.1: Multi-Vehicle Dashboard

As an authenticated user,
I want a dashboard that lists all my vehicles with their overall due-soon status at a glance,
So that I can immediately see which cars need attention without navigating to each one.

**Acceptance Criteria:**

**Given** I am signed in and have registered vehicles
**When** I visit the root path (`/`)
**Then** I see all my vehicles listed, each rendered via the `_vehicle_card` partial (FR27)
**And** each vehicle card shows a due-soon status indicator — green (all ok), amber (one or more due soon), or neutral (none configured) (FR28)

**Given** I have no registered vehicles
**When** I visit the dashboard
**Then** I see a friendly empty state with a prompt to add my first vehicle

**Given** I have up to 10 vehicles
**When** the dashboard loads
**Then** it renders in under 1 second (NFR3), using eager loading to prevent N+1 queries

**Given** I am on mobile
**When** I view the dashboard
**Then** vehicle cards are stacked and usable at 375px (NFR14)

### Story 5.2: Navigate to Vehicle Detail View

As an authenticated user,
I want to navigate from the dashboard to a per-vehicle detail view,
So that I can see the full service history and due-soon status for a specific car.

**Acceptance Criteria:**

**Given** I am on the dashboard
**When** I click on a vehicle card
**Then** I am taken to that vehicle's detail page (`vehicles#show`) (FR29)
**And** the detail page shows the vehicle's service history and per-service-type due-soon status (from Epic 4)

**Given** another user's vehicle ID is used directly in the URL
**When** the request is processed
**Then** I am redirected to root with a `flash[:alert]` (ARC5/ARC10)
