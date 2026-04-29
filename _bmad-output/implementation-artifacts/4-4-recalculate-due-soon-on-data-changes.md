# Story 4.4: Recalculate Due-Soon on Data Changes

Status: ready-for-dev

## Story

As an authenticated user,
I want the due-soon status to update automatically whenever I log a service, update mileage, or change a threshold,
so that the reminders always reflect the current state of my vehicle.

## Acceptance Criteria

1. **Given** I log a new service entry for a vehicle,
   **When** I am redirected to the vehicle detail page,
   **Then** the due-soon status for that service type reflects the new log entry (FR23)

2. **Given** I update a vehicle's current mileage,
   **When** I am redirected to the vehicle detail page,
   **Then** the due-soon status for all service types reflects the updated mileage (FR24)

3. **Given** I change a reminder threshold for a service type,
   **When** I am redirected to the vehicle detail page,
   **Then** the due-soon status for that service type reflects the new threshold (FR25)

4. **Given** all three recalculation triggers,
   **When** each is exercised in the test suite,
   **Then** `DueSoonCalculator.call` is the only calculation path invoked — no inline logic in controllers or views (ARC4)

## Tasks / Subtasks

- [ ] Task 1: Fix `ServiceLogEntriesController#create` redirect (AC: #1, #4)
  - [ ] Change successful-save redirect from `vehicle_service_log_entries_path(@vehicle)` to `vehicle_path(@vehicle)`
  - [ ] Update flash notice if desired (keep "Service entry logged successfully." — no change needed)
  - [ ] Update existing spec assertion in `spec/requests/service_log_entries_spec.rb` that expects redirect to `vehicle_service_log_entries_path(vehicle)` after create

- [ ] Task 2: Fix `ReminderThresholdsController` redirects (AC: #3, #4)
  - [ ] `create` success: change redirect from `vehicle_reminder_thresholds_path(@vehicle)` to `vehicle_path(@vehicle)`
  - [ ] `update` success: change redirect from `vehicle_reminder_thresholds_path(@vehicle)` to `vehicle_path(@vehicle)`
  - [ ] `update` blank-fields removal branch (calls `@threshold.destroy`): change redirect from `vehicle_reminder_thresholds_path(@vehicle)` to `vehicle_path(@vehicle)`
  - [ ] Update existing spec assertions in `spec/requests/reminder_thresholds_spec.rb` that expect redirect to `vehicle_reminder_thresholds_path(vehicle)` after create success, update success, and blank-fields removal

- [ ] Task 3: Add recalculation integration specs (AC: #1, #2, #3, #4)
  - [ ] In `spec/requests/service_log_entries_spec.rb` `POST create` context: setup vehicle with breached threshold, log a fresh service entry, follow redirect to vehicle show, verify badge transitions from `:due_soon` → `:ok` (confirms recalculation)
  - [ ] In `spec/requests/vehicles_spec.rb` `PATCH update_mileage` context: vehicle with 2 service types and breached thresholds, update mileage further, follow redirect, verify due-soon badges shown for both service types
  - [ ] In `spec/requests/reminder_thresholds_spec.rb` `PATCH update` context: lower a threshold's `mileage_interval` so current state becomes `:due_soon`, follow redirect to vehicle show, verify due-soon badge appears
  - [ ] In each new spec, verify `DueSoonCalculator.call` is invoked via `and_call_original` stub (same pattern as Story 4.3's delegation spec in `spec/requests/vehicles_spec.rb`)

## Dev Notes

### What's Already Done (Do NOT reinvent)

`vehicles#show` already calculates due-soon status via `DueSoonCalculator` since Story 4.3:
```ruby
def show
  @vehicle = current_user.vehicles
                         .includes(:service_log_entries, :reminder_thresholds)
                         .find(params[:id])
  build_due_soon_data   # calls DueSoonCalculator.call per service type
end
```
The `build_due_soon_data` private method is already correct. **Do not modify it.**

### What Needs Changing

**Current (broken) redirect in `ServiceLogEntriesController#create`:**
```ruby
# app/controllers/service_log_entries_controller.rb
def create
  @entry = @vehicle.service_log_entries.build(entry_params)
  if @entry.save
    redirect_to vehicle_service_log_entries_path(@vehicle), notice: "Service entry logged successfully."
    #           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ CHANGE THIS
```
**Fix:**
```ruby
    redirect_to vehicle_path(@vehicle), notice: "Service entry logged successfully."
```

**Current (broken) redirects in `ReminderThresholdsController`:**
```ruby
# app/controllers/reminder_thresholds_controller.rb
def create
  ...
  if @threshold.save
    redirect_to vehicle_reminder_thresholds_path(@vehicle), notice: "Reminder threshold saved."
    #           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ CHANGE THIS

def update
  ...
  if both_intervals_blank?(attrs)
    @threshold.destroy
    redirect_to vehicle_reminder_thresholds_path(@vehicle), notice: "Threshold removed."
    #           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ CHANGE THIS
  ...
  if @threshold.update(attrs)
    redirect_to vehicle_reminder_thresholds_path(@vehicle), notice: "Reminder threshold updated."
    #           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ CHANGE THIS
```
**Fix all three to:**
```ruby
    redirect_to vehicle_path(@vehicle), notice: "..."
```

### Existing Specs That Will Break (Must Update)

After changing the redirects, two existing spec assertions will fail. Update them:

**`spec/requests/service_log_entries_spec.rb`** — find:
```ruby
expect(response).to redirect_to(vehicle_service_log_entries_path(vehicle))
```
and change to:
```ruby
expect(response).to redirect_to(vehicle_path(vehicle))
```
(Only the `POST create` success case — the `follow_redirect!` line after it may also need updating if it currently checks the service log index content.)

**`spec/requests/reminder_thresholds_spec.rb`** — find ALL assertions redirecting to `vehicle_reminder_thresholds_path(vehicle)` in `create` success, `update` success, and blank-update removal cases:
```ruby
expect(response).to redirect_to(vehicle_reminder_thresholds_path(vehicle))
```
and change to:
```ruby
expect(response).to redirect_to(vehicle_path(vehicle))
```
(The `follow_redirect!` lines after these may also check page content — verify those still pass or update accordingly.)

### New Spec Pattern (Follow Story 4.3's Established Pattern)

Use this pattern for the three new recalculation integration specs:

```ruby
# Example: service_log_entries_spec.rb POST create — due-soon reflects new log
it "redirects to vehicle show where due-soon reflects the new log entry" do
  service_type = ServiceType.first
  create(:reminder_threshold, vehicle: vehicle, service_type: service_type, mileage_interval: 5_000)
  # vehicle current_mileage: 50_000, service at 49_000 → 1_000 km since service, within 5_000 interval → :ok
  # After logging service at same mileage → mileage_at_service bumped, days_remaining changes → still :ok
  # To trigger :due_soon: set last service far back so threshold is exceeded
  expect(DueSoonCalculator).to receive(:call).with(vehicle: vehicle, service_type: service_type).and_call_original.at_least(:once)
  post vehicle_service_log_entries_path(vehicle), params: { ... }
  expect(response).to redirect_to(vehicle_path(vehicle))
  follow_redirect!
  expect(response.body).to include(service_type.name)
end
```

Key patterns from Story 4.3 (already in codebase — reuse):
```ruby
create(:reminder_threshold, vehicle: vehicle, service_type: service_type, mileage_interval: 10_000)
create(:service_log_entry, vehicle: vehicle, service_type: service_type, mileage_at_service: 50_000, serviced_on: 6.months.ago)
# vehicle current_mileage: see factory default or set explicitly
```

### Architecture Compliance (Agents MUST follow)

- ❌ `Vehicle.find(params[:id])` — always `current_user.vehicles.find(...)`
- ❌ Inline due-soon calculation in controllers or views — always delegate to `DueSoonCalculator`
- ❌ `flash[:success]` or `flash[:error]` — only `flash[:notice]` and `flash[:alert]`
- ❌ Due-soon logic in model callbacks — all calculation in `DueSoonCalculator`
- ✅ `DueSoonCalculator.call(vehicle:, service_type:)` is the **only** due-soon calculation path
- ✅ No modifications to `DueSoonCalculator` itself — already complete since Story 4.1

### Data Flow After This Story

**Service log entry create (FR12, FR23) — fixed:**
```
POST /vehicles/:vehicle_id/service_log_entries
  → ServiceLogEntry.create → redirect_to vehicle_path(@vehicle)
  → vehicles#show → DueSoonCalculator.call per service type → updated badge
```

**Mileage update (FR8, FR24) — already correct:**
```
PATCH /vehicles/:id/update_mileage
  → vehicle.update → redirect_to vehicle_path(@vehicle)
  → vehicles#show → DueSoonCalculator.call per service type → updated badge
```

**Threshold update (FR17–FR20, FR25) — fixed:**
```
PATCH /vehicles/:vehicle_id/reminder_thresholds/:id
  → threshold.update → redirect_to vehicle_path(@vehicle)
  → vehicles#show → DueSoonCalculator.call per service type → updated badge
```

### Project Structure Notes

Only these files should be modified:
- `app/controllers/service_log_entries_controller.rb` — change `create` redirect only
- `app/controllers/reminder_thresholds_controller.rb` — change `update` redirect only
- `spec/requests/service_log_entries_spec.rb` — update broken assertion + add 1 new spec
- `spec/requests/vehicles_spec.rb` — add 1 new spec for mileage recalculation
- `spec/requests/reminder_thresholds_spec.rb` — update broken assertion + add 1 new spec

**Do NOT modify:**
- `app/services/due_soon_calculator.rb` — complete since Story 4.1
- `app/controllers/vehicles_controller.rb` — `show` and `update_mileage` already correct
- `app/views/vehicles/show.html.erb` — badge rendering already complete from Story 4.3

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 4.4]
- [Source: _bmad-output/planning-artifacts/architecture.md#Data Flow]
- [Source: _bmad-output/planning-artifacts/architecture.md#Enforcement Guidelines]
- [Source: app/controllers/service_log_entries_controller.rb]
- [Source: app/controllers/reminder_thresholds_controller.rb]
- [Source: app/controllers/vehicles_controller.rb]
- [Source: spec/requests/service_log_entries_spec.rb]
- [Source: spec/requests/reminder_thresholds_spec.rb]
- [Source: spec/requests/vehicles_spec.rb]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4.6

### Debug Log References

### Completion Notes List

### File List
