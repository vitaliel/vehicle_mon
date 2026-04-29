# Story 5.2: Navigate to Vehicle Detail View

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an authenticated user,
I want to navigate from the dashboard to a per-vehicle detail view,
so that I can see the full service history and due-soon status for a specific car.

## Acceptance Criteria

1. **Given** I am on the dashboard,
   **When** I click on a vehicle card (title or "View" button),
   **Then** I am taken to that vehicle's detail page (`vehicles#show`) (FR29)
   **And** the detail page shows the vehicle's service history link and per-service-type due-soon status

2. **Given** another user's vehicle ID is used directly in the URL,
   **When** the request is processed,
   **Then** I am redirected to root with a `flash[:alert]` (ARC5/ARC10)

## Tasks / Subtasks

- [x] Task 1: Make vehicle card title a clickable link (AC: #1)
  - [x] In `app/views/shared/_vehicle_card.html.erb`, wrap the `<h5>` title in `link_to vehicle_path(vehicle)` so clicking the vehicle name navigates to `vehicles#show`
  - [x] Keep the existing "View" button — do not remove it

- [x] Task 2: Add `flash[:alert]` assertion to cross-user redirect spec (AC: #2)
  - [x] In `spec/requests/vehicles_spec.rb`, find the `"redirects to root for another user's vehicle"` example under `GET /vehicles/:id`
  - [x] Add `follow_redirect!` and `expect(response.body).to include("Record not found")` **or** use `expect(flash[:alert]).to be_present` — see Dev Notes for the correct pattern

- [x] Task 3: Add navigation specs to dashboard_spec (AC: #1)
  - [x] In `spec/requests/dashboard_spec.rb`, under the `"when authenticated with vehicles"` context, add an example that verifies each vehicle card contains a link to `vehicle_path(vehicle)`

## Dev Notes

### What's Already Done — Do NOT reinvent

- `vehicles#show` is **fully implemented** since Stories 2.x / 4.3. It already:
  - Scopes via `current_user.vehicles.includes(:service_log_entries, :reminder_thresholds).find(params[:id])`
  - Calls `DueSoonCalculator.call(vehicle:, service_type:)` per service type via `build_due_soon_data`
  - Renders `@due_soon_statuses` as a per-service-type maintenance status table
  - Shows a "View Service History" link to `vehicle_service_log_entries_path(@vehicle)`
  - Redirects to `root_path` with `alert: "Record not found."` on cross-user access (via `ApplicationController#rescue_from ActiveRecord::RecordNotFound`)

- `app/views/shared/_vehicle_card.html.erb` already has a `link_to "View", vehicle_path(vehicle), class: "btn btn-sm btn-outline-primary"` button. **Extend only — do not replace.**

- `spec/requests/vehicles_spec.rb` under `GET /vehicles/:id` already covers:
  - Unauthenticated redirect
  - Showing own vehicle
  - Cross-user redirect to `root_path` (but **missing the `flash[:alert]` assertion** — that's Task 2)
  - Due-soon badges (OK, Due Soon, Not configured)
  - `DueSoonCalculator` delegation

### Task 1 Implementation — Vehicle Card Title as Link

**Current `_vehicle_card.html.erb` title line:**
```erb
<h5 class="card-title mb-0"><%= vehicle.year %> <%= vehicle.make %> <%= vehicle.model %></h5>
```

**Change to:**
```erb
<h5 class="card-title mb-0">
  <%= link_to "#{vehicle.year} #{vehicle.make} #{vehicle.model}", vehicle_path(vehicle) %>
</h5>
```

No other changes to the partial. The status badge, mileage, and action buttons remain exactly as they are.

### Task 2 — Flash Alert Spec Pattern

In `spec/requests/vehicles_spec.rb`, the current example:
```ruby
it "redirects to root for another user's vehicle" do
  other_vehicle = create(:vehicle, user: other_user)
  get vehicle_path(other_vehicle)
  expect(response).to redirect_to(root_path)
end
```

Expand it to also assert the flash. Use `follow_redirect!` to read the flash after the redirect response:
```ruby
it "redirects to root with flash[:alert] for another user's vehicle" do
  other_vehicle = create(:vehicle, user: other_user)
  get vehicle_path(other_vehicle)
  expect(response).to redirect_to(root_path)
  follow_redirect!
  expect(response.body).to include("Record not found")
end
```

**Why `follow_redirect!` not `flash[:alert]`:** In request specs, Rack::Test's `flash` helper accesses the flash *before* the redirect, not after. `follow_redirect!` + checking `response.body` for the rendered flash message is the reliable pattern in this project — see how `vehicles_spec.rb` POST examples use `follow_redirect!` to check flash notices.

### Task 3 — Dashboard Navigation Link Spec

Add inside `spec/requests/dashboard_spec.rb`, `"when authenticated with vehicles"` context:
```ruby
it "includes a link to each vehicle's detail page" do
  get root_path
  expect(response.body).to include(%(href="#{vehicle_path(vehicle)}"))
end
```

This verifies that the card (already rendered via `render 'shared/vehicle_card', vehicle: summary[:vehicle], status: summary[:status]`) contains a URL pointing at `vehicles#show`.

### Architecture Compliance (Agents MUST follow)

- ❌ Do NOT add a new controller action — `vehicles#show` already handles everything
- ❌ Do NOT change the ownership scoping — `current_user.vehicles.find(...)` must remain
- ❌ Do NOT use `flash[:success]` or `flash[:error]` — only `flash[:notice]` and `flash[:alert]`
- ❌ Do NOT call `DueSoonCalculator` in the view — it is called only from `VehiclesController#show`
- ✅ `_vehicle_card` extension: add link to title only — keep badge + buttons unchanged
- ✅ Cross-user protection already provided by `ApplicationController#rescue_from` — no new logic needed
- ✅ Flash message text "Record not found." is set in `ApplicationController#handle_not_found` — match exactly in the spec assertion

### Project Structure Notes

Files to **modify**:
- `app/views/shared/_vehicle_card.html.erb` — wrap `<h5>` title in `link_to vehicle_path(vehicle)`
- `spec/requests/vehicles_spec.rb` — add `flash[:alert]` assertion to cross-user redirect example
- `spec/requests/dashboard_spec.rb` — add link-to-detail-page navigation spec

Files to **leave untouched**:
- `app/controllers/vehicles_controller.rb` — already correct; no changes needed
- `app/views/vehicles/show.html.erb` — already shows service history link + due-soon status table
- `app/controllers/application_controller.rb` — RecordNotFound rescue already present
- All model and service files

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 5.2]
- [Source: _bmad-output/planning-artifacts/architecture.md#Enforcement Guidelines]
- [Source: _bmad-output/planning-artifacts/architecture.md#Ownership Boundary]
- [Source: _bmad-output/planning-artifacts/architecture.md#Format Patterns — Flash Messages]
- [Source: app/views/shared/_vehicle_card.html.erb — existing partial to extend]
- [Source: app/controllers/vehicles_controller.rb — show + build_due_soon_data already done]
- [Source: app/controllers/application_controller.rb — rescue_from RecordNotFound already done]
- [Source: spec/requests/vehicles_spec.rb — existing cross-user and follow_redirect! patterns]
- [Source: spec/requests/dashboard_spec.rb — existing context structure to extend]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4.6

### Debug Log References

### Completion Notes List

- Wrapped `<h5>` vehicle title in `link_to vehicle_path(vehicle)` in `_vehicle_card.html.erb`; existing "View" button retained.
- Updated cross-user redirect spec in `vehicles_spec.rb` to use `follow_redirect!` + `response.body.include?("Record not found")` — matches existing project pattern.
- Added navigation link spec in `dashboard_spec.rb` verifying `href` to `vehicle_path(vehicle)` is present in rendered response.
- All 183 tests pass, 0 failures.

### File List

- `app/views/shared/_vehicle_card.html.erb` — wrapped `<h5>` title in `link_to vehicle_path(vehicle)`
- `spec/requests/vehicles_spec.rb` — updated cross-user redirect example with flash alert assertion
- `spec/requests/dashboard_spec.rb` — added navigation link spec

## Change Log

- 2026-04-29: Implemented Story 5.2 — vehicle card title is now a link to `vehicles#show`; added flash alert assertion to cross-user redirect spec; added dashboard navigation link spec. All ACs satisfied. (183 tests, 0 failures)
