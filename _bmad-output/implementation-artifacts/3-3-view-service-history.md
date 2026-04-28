# Story 3.3: View Service History

Status: review

## Story

As an authenticated user,
I want to view all service log entries for a vehicle in chronological order,
so that I can review the full maintenance history at a glance.

## Acceptance Criteria

1. **Given** I own a vehicle with multiple service log entries, **When** I visit the vehicle's service log index, **Then** entries are listed in chronological order (oldest first) (FR16) **And** each entry shows: service type, date (formatted as "DD Mon YYYY"), mileage, service center, parts cost, labour cost, notes.

2. **Given** I own a vehicle with no service log entries, **When** I visit its service log index, **Then** I see a friendly empty state with a prompt to add the first entry.

3. **Given** I am on the vehicle detail page, **When** I look for navigation to service history, **Then** there is a clear link to the service history index for that vehicle.

4. **Given** I am on mobile (375px), **When** I view the service history list, **Then** the layout is readable and the table is horizontally scrollable.

5. **Given** another user's vehicle ID is in the URL, **When** I attempt to access its service log index, **Then** I am redirected to root with a `flash[:alert]`.

## Tasks / Subtasks

- [x] Task 1: Add "View Service History" navigation link on vehicle detail page (AC: #3)
  - [x] Add a link to `vehicle_service_log_entries_path(@vehicle)` in `app/views/vehicles/show.html.erb`

- [x] Task 2: Verify and expand index view for all AC field requirements (AC: #1, #2, #4)
  - [x] Confirm `index.html.erb` renders date with `strftime('%d %b %Y')`, mileage with `number_with_delimiter`, costs with `number_to_currency`, notes column present
  - [x] Confirm `table-responsive` wrapper is present for mobile horizontal scroll

- [x] Task 3: Expand request specs for story 3.3 ACs (AC: #1, #2, #3, #5)
  - [x] Add spec asserting chronological ordering (oldest entry appears before newer in response body)
  - [x] Add spec verifying field display: formatted date string (e.g. "01 Jan 2025"), delimited mileage, currency-formatted costs, notes text
  - [x] Add spec verifying vehicle show page contains link to service history (GET /vehicles/:id includes link text "Service History" or similar)
  - [x] Cross-user redirect spec already exists — confirm it covers 5th AC (no new spec needed)

## Dev Notes

### Current State: Largely Already Implemented in Story 3.2

Story 3.2 built the index action and view as a "minimal redirect target". The following are **already in place and must not be re-implemented**:

**Controller (`app/controllers/service_log_entries_controller.rb`):**
```ruby
def index
  @entries = @vehicle.service_log_entries.includes(:service_type).order(serviced_on: :asc)
end
```
- `before_action :set_vehicle` uses `current_user.vehicles.find(params[:vehicle_id])` — cross-user protection is automatic via `RecordNotFound` → `handle_not_found` in `ApplicationController`.
- `:includes(:service_type)` prevents N+1 queries.
- `order(serviced_on: :asc)` = oldest first. ✓

**View (`app/views/service_log_entries/index.html.erb`):**
- Full Bootstrap table already present with all required columns.
- Date formatted: `entry.serviced_on.strftime('%d %b %Y')` ✓
- Mileage: `number_with_delimiter(entry.mileage_at_service) %> km` ✓
- Costs: `number_to_currency(entry.parts_cost)` and `number_to_currency(entry.labour_cost)` ✓
- Empty state with "Log your first service entry" CTA ✓
- `table-responsive` wrapper ✓

**Existing specs (`spec/requests/service_log_entries_spec.rb`):**
- Unauthenticated redirect ✓
- Empty state text ✓
- Entries with service_type.name present ✓
- Cross-user redirect + flash[:alert] ✓

### What's Missing for Story 3.3

Only two small gaps remain:

**1. Navigation link from vehicle show page**

`app/views/vehicles/show.html.erb` has no link to the service history. Add one near the existing "← Back to Vehicles" button:

```erb
<%= link_to "View Service History", vehicle_service_log_entries_path(@vehicle), class: "btn btn-outline-primary" %>
```

**2. Richer request specs for field formatting and ordering**

The existing "lists existing entries in chronological order" test only checks `include(service_type.name)`. Add specs that verify:
- Formatted date string (e.g. the formatted version of a known date appears in the response body)
- Ordered rendering (first entry's mileage appears before second entry's mileage in HTML)
- Formatted cost display (e.g. `"$25.00"` or locale equivalent)
- Notes text appears in response

### Authorization Pattern (Must Follow)

Cross-user protection is **free** — `current_user.vehicles.find(params[:vehicle_id])` raises `RecordNotFound` when the vehicle doesn't belong to the signed-in user. `ApplicationController#handle_not_found` handles it:
```ruby
rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

def handle_not_found
  redirect_to root_path, alert: "Record not found."
end
```
Never add additional rescue blocks in `ServiceLogEntriesController`.

### Flash Keys

- Success: `flash[:notice]` only
- Error/redirect: `flash[:alert]` only
[Source: _bmad-output/planning-artifacts/architecture.md#Format Patterns]

### Format Conventions (Must Follow)

| Field | Storage | Display Helper | Example |
|-------|---------|----------------|---------|
| `serviced_on` | `date` | `strftime('%d %b %Y')` | "23 Apr 2026" |
| `mileage_at_service` | `integer` | `number_with_delimiter(x)` + " km" | "50,000 km" |
| `parts_cost`, `labour_cost` | `decimal(10,2)` | `number_to_currency(x)` | "$25.00" |
| `notes` | `text`, nullable | plain ERB output | "Changed oil" |

[Source: _bmad-output/planning-artifacts/architecture.md#Format Patterns]

### Routing (Already Configured)

```ruby
resources :vehicles do
  resources :service_log_entries  # ← already in config/routes.rb
end
```
Path helper: `vehicle_service_log_entries_path(@vehicle)` → `/vehicles/:vehicle_id/service_log_entries`

### Project Structure Notes

**Files to modify:**
- `app/views/vehicles/show.html.erb` — add navigation link to service history
- `spec/requests/service_log_entries_spec.rb` — expand index specs

**Files to NOT touch:**
- `app/controllers/service_log_entries_controller.rb` — index action is complete
- `app/views/service_log_entries/index.html.erb` — view already satisfies all display ACs
- `app/models/service_log_entry.rb` — no model changes needed
- `app/models/service_type.rb` — global catalog, untouched
- Any Epic 4 files (`due_soon_calculator.rb`, `reminder_thresholds`) — out of scope

### Previous Story Learnings (Story 3.2)

- All 102 specs pass (0 failures, 2 pre-existing pending stubs) — run `bundle exec rspec` before and after to confirm zero regressions.
- Factory: `create(:service_log_entry, vehicle: vehicle, service_type: service_type, serviced_on: ..., mileage_at_service: ...)` — all fields required at DB level.
- `create(:service_type)` defaults to name `"Engine Oil"` — specify `name:` explicitly when testing name-dependent display.
- Flash key check: use `flash[:alert]` (not `flash[:error]`).
- `sign_in user` via Devise test helpers in `spec/rails_helper.rb` support.

### References

- Story ACs: `_bmad-output/planning-artifacts/epics.md#Story 3.3: View Service History`
- Epic context: `_bmad-output/planning-artifacts/epics.md#Epic 3: Service History Logging`
- Format patterns: `_bmad-output/planning-artifacts/architecture.md#Format Patterns`
- Auth pattern: `_bmad-output/planning-artifacts/architecture.md#Authentication & Security`
- Existing controller: `app/controllers/service_log_entries_controller.rb`
- Existing index view: `app/views/service_log_entries/index.html.erb`
- Existing specs: `spec/requests/service_log_entries_spec.rb`
- Auth enforcement: `app/controllers/application_controller.rb`
- Routes: `config/routes.rb`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4.6

### Debug Log References

No blockers encountered.

### Completion Notes List

- Story 3.2 had already implemented the `index` action (chronological `order(serviced_on: :asc)`, `includes(:service_type)` for N+1 prevention) and the full `index.html.erb` view with all display formatting (date `strftime('%d %b %Y')`, `number_with_delimiter` km, `number_to_currency`, notes, `table-responsive`). Story 3.3 scope was surgical.
- Added `link_to "View Service History"` in `app/views/vehicles/show.html.erb` pointing to `vehicle_service_log_entries_path(@vehicle)`.
- Expanded `spec/requests/service_log_entries_spec.rb`: replaced the vague "chronological order" spec with 5 targeted specs covering ordering by mileage index position, date formatting ("23 Apr 2025"), mileage delimiter ("92,400"), cost formatting ("25.50", "80.00"), and notes text display.
- Added spec to `spec/requests/vehicles_spec.rb` asserting vehicle show page body includes `vehicle_service_log_entries_path(vehicle)` URL.
- All 107 specs pass (0 failures, 2 pre-existing pending stubs).

### File List

- `app/views/vehicles/show.html.erb` (modified — added service history navigation link)
- `spec/requests/service_log_entries_spec.rb` (modified — expanded index display/ordering specs)
- `spec/requests/vehicles_spec.rb` (modified — added service history link spec on show page)
- `_bmad-output/implementation-artifacts/3-3-view-service-history.md` (story updated)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (updated)

## Change Log

- 2026-04-28: Story 3.3 created — View Service History context prepared for development.
- 2026-04-28: Story 3.3 implemented — Added service history nav link on vehicle show page; expanded index display/ordering specs. 107 specs pass. Status → review.
