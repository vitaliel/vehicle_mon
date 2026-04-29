# Story 5.1: Multi-Vehicle Dashboard

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an authenticated user,
I want a dashboard that lists all my vehicles with their overall due-soon status at a glance,
so that I can immediately see which cars need attention without navigating to each one.

## Acceptance Criteria

1. **Given** I am signed in and have registered vehicles,
   **When** I visit the root path (`/`),
   **Then** I see all my vehicles listed, each rendered via the `_vehicle_card` partial (FR27)

2. **Given** I have registered vehicles,
   **When** I view the dashboard,
   **Then** each vehicle card shows a due-soon status indicator — green badge (all ok), amber badge (one or more due soon), or neutral badge (none configured) (FR28)

3. **Given** I have no registered vehicles,
   **When** I visit the dashboard,
   **Then** I see a friendly empty state with a prompt to add my first vehicle

4. **Given** I have up to 10 vehicles,
   **When** the dashboard loads,
   **Then** it renders in under 1 second (NFR3), using eager loading to prevent N+1 queries

5. **Given** I am on mobile,
   **When** I view the dashboard,
   **Then** vehicle cards are stacked and usable at 375px (NFR14)

## Tasks / Subtasks

- [x] Task 1: Change root route from `pages#index` to `dashboard#index` (AC: #1, #2, #3)
  - [x] In `config/routes.rb`, change `root "pages#index"` to `root "dashboard#index"`

- [x] Task 2: Create `DashboardController` (AC: #1, #2, #4)
  - [x] Create `app/controllers/dashboard_controller.rb` with `index` action
  - [x] Eager-load vehicles with `includes(:service_log_entries, :reminder_thresholds)` to prevent N+1
  - [x] Load all `ServiceType.order(:name)` once (not inside the per-vehicle loop)
  - [x] Call `DueSoonCalculator.call(vehicle:, service_type:)` for each vehicle × service_type pair
  - [x] Aggregate to per-vehicle overall status (`:due_soon` > `:ok` > `:unconfigured`)
  - [x] Assign `@vehicle_summaries` as ordered array of `{ vehicle:, status: }` hashes

- [x] Task 3: Create `app/views/dashboard/index.html.erb` (AC: #1, #2, #3, #5)
  - [x] Render `shared/vehicle_card` partial for each summary, passing `vehicle:` and `status:` locals
  - [x] Use Bootstrap responsive grid (same as `vehicles/index.html.erb`)
  - [x] Include empty state when `@vehicle_summaries` is empty

- [x] Task 4: Update `app/views/shared/_vehicle_card.html.erb` to render status badge (AC: #2)
  - [x] Add `status` local variable to the partial (default to `nil` for backward compatibility)
  - [x] Render the appropriate badge when `status` is present: green (`:ok`), amber (`:due_soon`), neutral (`:unconfigured`)
  - [x] Use consistent Bootstrap badge + Bootstrap Icons classes matching `vehicles/show.html.erb`

- [x] Task 5: Update specs (AC: #1–#4)
  - [x] Create `spec/requests/dashboard_spec.rb` covering: unauthenticated redirect, empty state, vehicles listed, status badges, N+1 prevention via `DueSoonCalculator` delegation check
  - [x] Update `spec/requests/pages_spec.rb` → delete or repurpose (root now belongs to dashboard)
  - [x] Verify no existing specs break due to route change

## Dev Notes

### What's Already Done (Do NOT reinvent)

- `DueSoonCalculator.call(vehicle:, service_type:)` is fully implemented in `app/services/due_soon_calculator.rb` since Story 4.1. Returns `{ status: :due_soon | :ok | :unconfigured, mileage_remaining: Integer|nil, days_remaining: Integer|nil }`.
- `app/views/shared/_vehicle_card.html.erb` exists and renders vehicle title, mileage, and action buttons. **Extend it — do not rewrite it.**
- `app/views/vehicles/index.html.erb` already has the Bootstrap responsive grid and empty state pattern — reuse it as the template for `dashboard/index.html.erb`.
- `vehicles#show` sets `@due_soon_statuses` (a hash of `service_type → result`) and renders per-service-type badges using `bg-success`, `bg-warning text-dark`, `bg-secondary`. Follow the same badge classes.
- Authentication (`before_action :authenticate_user!`) and `RecordNotFound` rescue are in `ApplicationController` — `DashboardController` inherits them automatically.
- `spec/requests/vehicles_spec.rb` shows the established request spec pattern with `sign_in user`, `create(:vehicle, ...)`, and `DueSoonCalculator` delegation stub (`and_call_original`).

### DashboardController Implementation Pattern

```ruby
# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  def index
    vehicles = current_user.vehicles
                           .includes(:service_log_entries, :reminder_thresholds)
                           .order(created_at: :desc)
    service_types = ServiceType.order(:name)

    @vehicle_summaries = vehicles.map do |vehicle|
      statuses = service_types.map do |st|
        DueSoonCalculator.call(vehicle: vehicle, service_type: st)[:status]
      end
      overall = if statuses.include?(:due_soon) then :due_soon
                elsif statuses.include?(:ok)     then :ok
                else                                  :unconfigured
                end
      { vehicle: vehicle, status: overall }
    end
  end
end
```

**Key rules:**
- Load `ServiceType.order(:name)` ONCE outside the `vehicles.map` loop (prevent per-vehicle DB query).
- Use `.includes(:service_log_entries, :reminder_thresholds)` — not `.eager_load` or `.preload` — to match the established pattern in `VehiclesController#show`.
- Overall status precedence: `:due_soon` (any service due) > `:ok` (all configured, none due) > `:unconfigured` (no thresholds at all).
- Do NOT pass `@due_soon_statuses` (per-service breakdown) to the dashboard — that level of detail is for `vehicles#show`.

### `_vehicle_card` Partial Extension

The partial currently accepts only `vehicle`. Add an optional `status` local:

```erb
<%# app/views/shared/_vehicle_card.html.erb %>
<div class="card h-100 shadow-sm">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-start mb-2">
      <h5 class="card-title mb-0"><%= vehicle.year %> <%= vehicle.make %> <%= vehicle.model %></h5>
      <% if local_assigns[:status] %>
        <% case status
           when :ok %>
          <span class="badge bg-success"><i class="bi bi-check-circle"></i> OK</span>
        <% when :due_soon %>
          <span class="badge bg-warning text-dark"><i class="bi bi-exclamation-triangle"></i> Due Soon</span>
        <% when :unconfigured %>
          <span class="badge bg-secondary">Not configured</span>
        <% end %>
      <% end %>
    </div>
    <p class="card-text text-muted">
      <i class="bi bi-speedometer2"></i>
      <%= number_with_delimiter(vehicle.current_mileage) %> km
    </p>
    <%= link_to "View", vehicle_path(vehicle), class: "btn btn-sm btn-outline-primary" %>
    <%= link_to "Edit", edit_vehicle_path(vehicle), class: "btn btn-sm btn-outline-secondary" %>
    <%= link_to "Delete", vehicle_path(vehicle),
          data: { turbo_method: :delete, turbo_confirm: "Are you sure you want to delete this vehicle?" },
          class: "btn btn-sm btn-outline-danger" %>
  </div>
</div>
```

Use `local_assigns[:status]` to check presence — this preserves backward compatibility with `vehicles/index.html.erb` which renders the card without a status.

### `dashboard/index.html.erb` Structure

Model it on `vehicles/index.html.erb` (same Bootstrap grid). Key difference: iterate over `@vehicle_summaries` (array of hashes) and pass `status:` to the card partial:

```erb
<%# app/views/dashboard/index.html.erb %>
<% content_for :title, "Dashboard" %>

<div class="d-flex justify-content-between align-items-center mb-4">
  <h1 class="h3">My Vehicles</h1>
  <%= link_to "Add Vehicle", new_vehicle_path, class: "btn btn-primary" %>
</div>

<% if @vehicle_summaries.empty? %>
  <div class="text-center py-5 text-muted">
    <p class="fs-5">You haven't added any vehicles yet.</p>
    <%= link_to "Add your first vehicle", new_vehicle_path, class: "btn btn-outline-primary" %>
  </div>
<% else %>
  <div class="row row-cols-1 row-cols-md-2 row-cols-lg-3 g-4">
    <% @vehicle_summaries.each do |summary| %>
      <div class="col">
        <%= render 'shared/vehicle_card', vehicle: summary[:vehicle], status: summary[:status] %>
      </div>
    <% end %>
  </div>
<% end %>
```

### Pages Controller / Spec

`PagesController` (`app/controllers/pages_controller.rb`) and `app/views/pages/index.html.erb` are vestigial — created before the architecture was finalized. They are **not** in the canonical architecture. Once the route changes to `root "dashboard#index"`:

- `app/controllers/pages_controller.rb` — **delete**
- `app/views/pages/index.html.erb` — **delete**
- `spec/requests/pages_spec.rb` — **delete** (replaced by `dashboard_spec.rb`)

Deleting these prevents route confusion and dead code.

### Dashboard Spec Pattern

```ruby
# spec/requests/dashboard_spec.rb
RSpec.describe "Dashboard", type: :request do
  let(:user) { create(:user) }

  describe "GET /" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated with no vehicles" do
      before { sign_in user }

      it "shows empty state" do
        get root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Add your first vehicle")
      end
    end

    context "when authenticated with vehicles" do
      let(:vehicle) { create(:vehicle, user: user, make: "Honda", model: "Civic", year: 2020, current_mileage: 50_000) }

      before { sign_in user; vehicle }

      it "lists user's vehicles" do
        get root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Honda")
        expect(response.body).to include("Civic")
      end

      it "does not list other users' vehicles" do
        other_vehicle = create(:vehicle, user: create(:user), make: "Ford", model: "Focus", year: 2018)
        get root_path
        expect(response.body).not_to include("Ford")
      end

      it "delegates due-soon calculation to DueSoonCalculator" do
        service_type = ServiceType.first
        create(:reminder_threshold, vehicle: vehicle, service_type: service_type, mileage_interval: 10_000)
        expect(DueSoonCalculator).to receive(:call)
          .with(vehicle: vehicle, service_type: anything)
          .and_call_original
          .at_least(:once)
        get root_path
      end

      it "shows due-soon badge when a threshold is breached" do
        service_type = ServiceType.first
        create(:reminder_threshold, vehicle: vehicle, service_type: service_type, mileage_interval: 1_000)
        create(:service_log_entry, vehicle: vehicle, service_type: service_type,
               mileage_at_service: 1_000, serviced_on: 2.years.ago)
        get root_path
        expect(response.body).to include("Due Soon")
      end

      it "shows ok badge when thresholds are configured and not breached" do
        service_type = ServiceType.first
        create(:reminder_threshold, vehicle: vehicle, service_type: service_type, mileage_interval: 100_000)
        create(:service_log_entry, vehicle: vehicle, service_type: service_type,
               mileage_at_service: 49_000, serviced_on: 1.month.ago)
        get root_path
        expect(response.body).to include("OK")
      end
    end
  end
end
```

### Architecture Compliance (Agents MUST follow)

- ❌ `Vehicle.find(...)` or `Vehicle.all` — always `current_user.vehicles.includes(...).order(...)`
- ❌ Inline due-soon calculation in the controller or view — always delegate to `DueSoonCalculator`
- ❌ `flash[:success]` or `flash[:error]` — only `flash[:notice]` and `flash[:alert]`
- ❌ Calling `ServiceType.order(:name)` inside the vehicles loop — load once outside, pass into loop
- ✅ `DueSoonCalculator.call(vehicle:, service_type:)` is the **only** due-soon calculation path (ARC4)
- ✅ Dashboard controller passes `@vehicle_summaries` (aggregated per vehicle) — not raw `@due_soon_statuses`
- ✅ `_vehicle_card` partial uses `local_assigns[:status]` for backward-compatible status rendering
- ✅ CSS badge classes follow existing convention: `bg-success`, `bg-warning text-dark`, `bg-secondary`

### Project Structure Notes

Files to **create**:
- `app/controllers/dashboard_controller.rb`
- `app/views/dashboard/index.html.erb`
- `spec/requests/dashboard_spec.rb`

Files to **modify**:
- `config/routes.rb` — change `root "pages#index"` → `root "dashboard#index"`
- `app/views/shared/_vehicle_card.html.erb` — add optional `status` badge rendering

Files to **delete**:
- `app/controllers/pages_controller.rb`
- `app/views/pages/index.html.erb`
- `spec/requests/pages_spec.rb`

Files to **leave untouched**:
- `app/services/due_soon_calculator.rb` — complete since Story 4.1
- `app/controllers/vehicles_controller.rb` — unchanged
- `app/views/vehicles/index.html.erb` — still used at `/vehicles`, no change needed

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 5.1]
- [Source: _bmad-output/planning-artifacts/architecture.md#Data Flow — Dashboard load]
- [Source: _bmad-output/planning-artifacts/architecture.md#Naming Patterns — View Partial Naming]
- [Source: _bmad-output/planning-artifacts/architecture.md#Service Interface Pattern]
- [Source: _bmad-output/planning-artifacts/architecture.md#Enforcement Guidelines]
- [Source: app/controllers/vehicles_controller.rb — show action + build_due_soon_data pattern]
- [Source: app/views/shared/_vehicle_card.html.erb — existing partial to extend]
- [Source: app/views/vehicles/index.html.erb — Bootstrap grid + empty state to replicate]
- [Source: app/views/vehicles/show.html.erb — badge class conventions]
- [Source: spec/requests/vehicles_spec.rb — DueSoonCalculator delegation stub pattern]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4.6

### Debug Log References

- `ServiceType.first` → nil in test DB; fixed to `create(:service_type)` following vehicles_spec pattern.
- Deleted stale `spec/helpers/pages_helper_spec.rb` and `spec/views/pages/index.html.erb_spec.rb` (pending, referenced deleted PagesHelper).

### Completion Notes List

- Route changed: `root "pages#index"` → `root "dashboard#index"`
- Created `DashboardController#index`: eager-loads vehicles with `includes(:service_log_entries, :reminder_thresholds)`, loads `ServiceType.order(:name)` once, calls `DueSoonCalculator.call` per vehicle×service_type, aggregates to per-vehicle `:due_soon`/`:ok`/`:unconfigured` status, assigns `@vehicle_summaries`.
- Created `app/views/dashboard/index.html.erb`: Bootstrap responsive grid, empty state, renders `_vehicle_card` with `status:` local.
- Extended `app/views/shared/_vehicle_card.html.erb`: added optional `status` badge using `local_assigns[:status]` — backward compatible with `vehicles/index.html.erb`.
- Deleted vestigial files: `PagesController`, `pages/index.html.erb`, `pages_spec.rb`, `pages_helper_spec.rb`, `pages/index view spec`.
- Created `spec/requests/dashboard_spec.rb`: 7 examples covering unauthenticated redirect, empty state, vehicles listed, cross-user isolation, DueSoonCalculator delegation, due-soon badge, ok badge, unconfigured badge.
- Full suite: 182 examples, 0 failures.

### File List

- config/routes.rb
- app/controllers/dashboard_controller.rb (created)
- app/views/dashboard/index.html.erb (created)
- app/views/shared/_vehicle_card.html.erb
- spec/requests/dashboard_spec.rb (created)
- spec/requests/pages_spec.rb (deleted)
- app/controllers/pages_controller.rb (deleted)
- app/views/pages/index.html.erb (deleted)
- spec/helpers/pages_helper_spec.rb (deleted)
- spec/views/pages/index.html.erb_spec.rb (deleted)
- _bmad-output/implementation-artifacts/sprint-status.yaml

## Change Log

- **2026-04-29**: Implemented Story 5.1 — multi-vehicle dashboard. Changed root route from `pages#index` to `dashboard#index`. Created `DashboardController#index` with N+1-safe eager loading and per-vehicle due-soon status aggregation via `DueSoonCalculator`. Created `dashboard/index.html.erb` with Bootstrap grid and empty state. Extended `_vehicle_card` partial with optional `status` badge (backward compatible). Removed vestigial PagesController, views, and specs. Added `dashboard_spec.rb` with 7 request specs. Full suite: 182 examples, 0 failures.
