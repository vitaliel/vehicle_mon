# Story 4.3: Due-Soon Status on Vehicle Detail View

Status: done

## Story

As an authenticated user,
I want to see the due-soon status for every service type on my vehicle's detail page,
so that I know exactly which services are coming up and how much time or mileage I have left.

## Acceptance Criteria

1. **Given** a vehicle has thresholds configured and log entries exist,
   **When** I visit the vehicle's detail page (`vehicles#show`),
   **Then** each service type shows its status badge: `:ok` (green), `:due_soon` (yellow/amber), or `:unconfigured` (neutral) (FR30, NFR13)
   **And** `:ok` and `:due_soon` entries display estimated mileage remaining and/or days remaining.

2. **Given** a service type has no threshold configured,
   **When** I view that service type on the detail page,
   **Then** it shows a neutral "Not configured" state — not an error (FR26).

3. **Given** the page loads with up to all 6 service types across multiple log entries,
   **When** the page renders,
   **Then** it completes in under 500ms (NFR2) by calling `DueSoonCalculator.call` per service type — never reimplementing calculation logic inline (ARC4).

## Tasks / Subtasks

- [x] Task 1: Modify `VehiclesController#show` to compute due-soon data (AC: #1, #2, #3)
  - [x] Reload `@vehicle` with eager-loaded associations: `current_user.vehicles.includes(:service_log_entries, :reminder_thresholds).find(params[:id])` in `set_vehicle` OR eager-load inside `show`
  - [x] Load all service types: `@service_types = ServiceType.order(:name)`
  - [x] Build `@due_soon_statuses` hash: `{ service_type => DueSoonCalculator.call(vehicle: @vehicle, service_type: service_type) }` for each service type
  - [x] Assign both `@service_types` and `@due_soon_statuses` as instance variables — **no logic in view**

- [x] Task 2: Update `app/views/vehicles/show.html.erb` to render due-soon section (AC: #1, #2)
  - [x] Add a "Maintenance Status" section below the mileage update card
  - [x] Iterate `@due_soon_statuses` — one row per service type
  - [x] Render Bootstrap badge per status:
    - `:ok` → `badge bg-success` — show `mileage_remaining` km and/or `days_remaining` days if present
    - `:due_soon` → `badge bg-warning text-dark` — show remaining values; 0 or negative means overdue
    - `:unconfigured` → `badge bg-secondary` — show "Not configured"
  - [x] Display `mileage_remaining` only when non-nil; display `days_remaining` only when non-nil

- [x] Task 3: Extend `spec/requests/vehicles_spec.rb` with due-soon display specs (AC: #1, #2, #3)
  - [x] `GET /vehicles/:id` — with configured threshold and log entry: shows service type name, green "ok" badge (or relevant badge text)
  - [x] `GET /vehicles/:id` — with `:due_soon` threshold breached: shows yellow/amber badge
  - [x] `GET /vehicles/:id` — with no threshold configured: shows "Not configured" text for that service type
  - [x] `GET /vehicles/:id` — all 6 seeded service types appear in the due-soon section
  - [x] Verify `DueSoonCalculator.call` is invoked (via stub or by confirming badge output), never inline logic

### Review Findings

- [x] [Review][Patch] Avoid N+1 query path when `update_mileage` render falls back to `:show` [app/controllers/vehicles_controller.rb:48]
- [x] [Review][Patch] Omit nil remaining values instead of rendering placeholder dashes [app/views/vehicles/show.html.erb:53]

## Dev Notes

### Current State Summary

**`VehiclesController#show` currently does nothing:**
```ruby
def show
end
```
The `set_vehicle` before_action already scopes via `current_user.vehicles.find(params[:id])` — no bare finder.

**`DueSoonCalculator` interface (canonical — MUST use exactly this):**
```ruby
result = DueSoonCalculator.call(vehicle: @vehicle, service_type: service_type)
# Returns:
# {
#   status: :due_soon | :ok | :unconfigured,
#   mileage_remaining: Integer | nil,   # nil if no mileage threshold
#   days_remaining:    Integer | nil    # nil if no time threshold
# }
```
- `:unconfigured` — no `ReminderThreshold` row for this vehicle+service_type
- `:due_soon` — either `mileage_remaining <= 0` OR `days_remaining <= 0`
- `:ok` — thresholds exist, neither breached

**`DueSoonCalculator` already queries `ReminderThreshold` and `ServiceLogEntry` internally.** Eager-loading `service_log_entries` and `reminder_thresholds` on `@vehicle` prevents N+1 (DueSoonCalculator uses the already-loaded AR associations if preloaded).

**Schema (no migration needed — complete since 4.1):**
```
service_types:          id, name
reminder_thresholds:    id, vehicle_id, service_type_id, mileage_interval, time_interval_months
service_log_entries:    id, vehicle_id, service_type_id, serviced_on, mileage_at_service, ...
```

**`app/views/vehicles/show.html.erb` currently contains:** mileage update form card, links to "View Service History", "Configure Reminders", "← Back to Vehicles". Add the maintenance status table **below** the mileage card and **above** the action links.

**6 seeded `ServiceType` records:** engine oil, spark plugs, air filter, brake pads, transmission fluid, tires (created in Story 3.1 seed). `ServiceType.order(:name)` retrieves all.

### N+1 Prevention (Critical for Performance AC)

Load associations before passing vehicle to `DueSoonCalculator`:

```ruby
# Option A: update set_vehicle (preferred — used on show only with eager load)
def show
  @vehicle = current_user.vehicles
                         .includes(:service_log_entries, :reminder_thresholds)
                         .find(params[:id])
  @service_types    = ServiceType.order(:name)
  @due_soon_statuses = @service_types.each_with_object({}) do |st, h|
    h[st] = DueSoonCalculator.call(vehicle: @vehicle, service_type: st)
  end
end
```

Do **not** change `set_vehicle` for all actions — other actions (edit, update, destroy, update_mileage) don't need the associations.

### Enforcement Guidelines (Architecture — Agents MUST follow)

- ❌ `Vehicle.find(params[:id])` — always `current_user.vehicles.find(...)`
- ❌ Inline due-soon calculation in controller or view — always delegate to `DueSoonCalculator`
- ❌ `flash[:success]` or `flash[:error]` — only `flash[:notice]` and `flash[:alert]`
- ❌ Business logic in views — pass `@due_soon_statuses` from controller
- ✅ `DueSoonCalculator.call(vehicle:, service_type:)` is the **only** due-soon calculation path

### View Badge Rendering Pattern

```erb
<% @due_soon_statuses.each do |service_type, result| %>
  <tr>
    <td><%= service_type.name %></td>
    <td>
      <% case result[:status]
         when :ok %>
        <span class="badge bg-success">OK</span>
      <% when :due_soon %>
        <span class="badge bg-warning text-dark">Due Soon</span>
      <% when :unconfigured %>
        <span class="badge bg-secondary">Not configured</span>
      <% end %>
    </td>
    <td>
      <% if result[:mileage_remaining] %>
        <%= number_with_delimiter(result[:mileage_remaining]) %> km remaining
      <% end %>
    </td>
    <td>
      <% if result[:days_remaining] %>
        <%= result[:days_remaining] %> days remaining
      <% end %>
    </td>
  </tr>
<% end %>
```

### Previous Story Learnings (4.2)

- **`service_type_id` scoping:** In 4.2, a review finding noted `service_type_id` could be changed via crafted update. For this story, `@service_types` comes from a DB query on `ServiceType` (global read-only); no user input touches service type identity — no scoping issue here.
- **Factory patterns established:**
  ```ruby
  create(:reminder_threshold, vehicle: vehicle, service_type: service_type, mileage_interval: 10_000)
  create(:service_log_entry, vehicle: vehicle, service_type: service_type, mileage_at_service: 50_000, serviced_on: 6.months.ago)
  ```
- **Controller pattern:** `before_action :set_vehicle` scoped through `current_user.vehicles` — already in place, do not change this pattern.
- **Request spec structure:** Use `let(:user)`, `let(:other_user)`, `sign_in user` in `before` blocks. Authorization tested with `other_user`'s vehicle.

### Project Structure Notes

- Controller: `app/controllers/vehicles_controller.rb` — modify `show` action only
- View: `app/views/vehicles/show.html.erb` — add maintenance status section
- Service: `app/services/due_soon_calculator.rb` — **DO NOT MODIFY** — already correct
- Spec: `spec/requests/vehicles_spec.rb` — extend `GET /vehicles/:id` describe block

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 4.3]
- [Source: _bmad-output/planning-artifacts/architecture.md#Service Interface Pattern]
- [Source: _bmad-output/planning-artifacts/architecture.md#Enforcement Guidelines]
- [Source: _bmad-output/planning-artifacts/architecture.md#Data Flow — Gap Analysis]
- [Source: _bmad-output/planning-artifacts/architecture.md#Complete Project Directory Structure]
- [Source: app/services/due_soon_calculator.rb]
- [Source: app/controllers/vehicles_controller.rb]
- [Source: app/views/vehicles/show.html.erb]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4.6

### Debug Log References

### Completion Notes List

- Implemented `VehiclesController#show` with eager-loading of `:service_log_entries` and `:reminder_thresholds` to prevent N+1 queries; extracted shared `build_due_soon_data` private method also called from `update_mileage` failure path (which renders `:show`).
- Updated `app/views/vehicles/show.html.erb` with a "Maintenance Status" table section rendering Bootstrap badges (`bg-success` / `bg-warning text-dark` / `bg-secondary`) for `:ok` / `:due_soon` / `:unconfigured` states; mileage_remaining and days_remaining shown conditionally.
- Added 5 new request specs covering all badge states, all-6-service-types display, and DueSoonCalculator delegation. Fixed lazy `let` ordering issue — service_type materialized before the request in the "Not configured" test.
- Full regression suite: 175 examples, 0 failures.

### File List

- `app/controllers/vehicles_controller.rb`
- `app/views/vehicles/show.html.erb`
- `spec/requests/vehicles_spec.rb`
