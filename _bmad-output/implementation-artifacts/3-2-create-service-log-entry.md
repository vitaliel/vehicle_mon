# Story 3.2: Create Service Log Entry

Status: ready-for-dev

## Story

As an authenticated user,
I want to log a service entry for one of my vehicles by selecting a service type from the catalog,
so that I have a permanent record of every maintenance event.

## Acceptance Criteria

1. **Given** I own a vehicle and service types are seeded, **When** I visit the new service log entry form for my vehicle, **Then** I see a dropdown of all service types (FR11) **And** all fields have associated labels: date, mileage at service, service center name, parts cost, labour cost, notes (optional) (FR13, NFR11).

2. **Given** I fill in all required fields and submit, **When** the entry is saved, **Then** it appears in my vehicle's service history **And** a `flash[:notice]` confirmation is shown **And** the save completes in under 500ms (NFR2).

3. **Given** I submit without a required field (date or mileage at service), **When** the form is submitted, **Then** I see a validation error and the form re-renders with `status: 422`.

4. **Given** another user's vehicle ID is in the URL, **When** I attempt to access the new entry form, **Then** I am redirected to root with a `flash[:alert]` (ARC5/ARC10).

## Tasks / Subtasks

- [ ] Task 1: Migrate `service_log_entries` table to add all required columns (AC: #1, #2)
  - [ ] Create migration to add to `service_log_entries`: `service_type_id` (bigint, not null, FK), `serviced_on` (date, not null), `mileage_at_service` (integer, not null), `service_center` (string, not null), `parts_cost` (decimal 10,2, not null, default 0), `labour_cost` (decimal 10,2, not null, default 0), `notes` (text, nullable).
  - [ ] Add DB index on `service_log_entries.service_type_id`.
  - [ ] Add FK constraint `service_log_entries → service_types`.

- [ ] Task 2: Update `ServiceLogEntry` model (AC: #1, #2, #3)
  - [ ] Add `belongs_to :service_type` association.
  - [ ] Add validations: `service_type` presence, `serviced_on` presence, `mileage_at_service` numericality (only_integer, ≥ 0), `service_center` presence, `parts_cost` numericality (≥ 0), `labour_cost` numericality (≥ 0).
  - [ ] `notes` is optional — no presence validation.

- [ ] Task 3: Create `ServiceLogEntriesController` (AC: #2, #3, #4)
  - [ ] `before_action :set_vehicle` — uses `current_user.vehicles.find(params[:vehicle_id])` (triggers `RecordNotFound` → `handle_not_found` for cross-user access).
  - [ ] `before_action :set_entry, only: [:show, :edit, :update, :destroy]` — scoped through `@vehicle.service_log_entries.find(params[:id])`.
  - [ ] `new` — builds `@entry = @vehicle.service_log_entries.build` and sets `@service_types`.
  - [ ] `create` — builds, saves, on success redirects to `vehicle_service_log_entries_path(@vehicle)` with `flash[:notice]`, on failure re-renders `:new` with `status: :unprocessable_entity`.
  - [ ] `index` — scoped entries for AC coverage (Story 3.3 expands this; a minimal index is needed so create can redirect to it).

- [ ] Task 4: Create views (AC: #1, #2, #3)
  - [ ] `app/views/service_log_entries/_form.html.erb` — Bootstrap form with labeled fields: service_type select (ordered by name), date_field for `serviced_on`, number_field for `mileage_at_service`, text_field for `service_center`, number_field (step 0.01, min 0) for `parts_cost` and `labour_cost`, text_area for `notes`.
  - [ ] `app/views/service_log_entries/new.html.erb` — renders `_form` partial.
  - [ ] `app/views/service_log_entries/index.html.erb` — minimal list (used as redirect target after create); full display is Story 3.3.

- [ ] Task 5: Create factory and request specs (AC: all)
  - [ ] `spec/factories/service_log_entries.rb` — factory with all required fields, association to vehicle and service_type.
  - [ ] `spec/requests/service_log_entries_spec.rb` — cover: unauthenticated redirect, cross-user redirect (AC#4), GET new returns 200, POST create valid → redirect + notice, POST create missing required field → 422, entry is scoped to vehicle.

## Dev Notes

### Critical: Existing `service_log_entries` Table is Incomplete

The current `service_log_entries` table (created in the project scaffold) only has `vehicle_id` + timestamps. **Do not recreate the table — add columns via a new migration.** Architecture's canonical schema requires:

```
service_log_entries: id, vehicle_id, service_type_id, serviced_on, mileage_at_service,
                     service_center, parts_cost, labour_cost, notes
```

Migration example:
```ruby
add_reference :service_log_entries, :service_type, null: false, foreign_key: true, index: true
add_column :service_log_entries, :serviced_on, :date, null: false
add_column :service_log_entries, :mileage_at_service, :integer, null: false
add_column :service_log_entries, :service_center, :string, null: false
add_column :service_log_entries, :parts_cost, :decimal, precision: 10, scale: 2, null: false, default: 0
add_column :service_log_entries, :labour_cost, :decimal, precision: 10, scale: 2, null: false, default: 0
add_column :service_log_entries, :notes, :text
```

### Authorization Pattern (Must Follow)

Use the established association-scoping chain. **Never** use bare `Vehicle.find` or `ServiceLogEntry.find`:

```ruby
# Correct — triggers RecordNotFound for cross-user access (ApplicationController rescues → root + alert)
@vehicle = current_user.vehicles.find(params[:vehicle_id])
@entry   = @vehicle.service_log_entries.find(params[:id])
```

`ApplicationController#handle_not_found` already handles `ActiveRecord::RecordNotFound` → `redirect_to root_path, alert: "Record not found."`. No extra rescue needed in `ServiceLogEntriesController`. [Source: app/controllers/application_controller.rb]

### Routing (Already Configured)

Routes are already defined:
```ruby
resources :vehicles do
  resources :service_log_entries   # ← already in config/routes.rb
  ...
end
```
URLs: `/vehicles/:vehicle_id/service_log_entries`, `/vehicles/:vehicle_id/service_log_entries/new`.
Path helpers: `vehicle_service_log_entries_path(@vehicle)`, `new_vehicle_service_log_entry_path(@vehicle)`.
[Source: config/routes.rb]

### ServiceType Dropdown

Query service types ordered by name for the dropdown — this guarantees a consistent, deterministic order for users and tests:

```ruby
@service_types = ServiceType.order(:name)
```

Use `collection_select` or `select` tag in the form to bind to `service_type_id`.

### Flash Keys

- Success: `flash[:notice]` only (never `:success`, `:info`)
- Error/redirect: `flash[:alert]` only (never `:error`, `:danger`)
[Source: _bmad-output/planning-artifacts/architecture.md#Format Patterns]

### Cost & Mileage Field Conventions

- Cost fields: `decimal(10, 2)`, form uses `number_field step: 0.01, min: 0`, display with `number_to_currency`.
- Mileage: `integer`, form uses `number_field`, display with `number_with_delimiter`.
- Date: `date` column, form uses `date_field`, display with `strftime('%d %b %Y')`.
[Source: _bmad-output/planning-artifacts/architecture.md#Format Patterns]

### Turbo Compatibility

On validation failure, render `:new` with `status: :unprocessable_entity` (HTTP 422). This is required for Turbo Drive to replace the page correctly instead of treating the response as a redirect.
[Source: _bmad-output/planning-artifacts/architecture.md#API & Communication Patterns, ARC11]

### Project Structure Notes

Files to create:
- `db/migrate/*_add_columns_to_service_log_entries.rb`
- `app/controllers/service_log_entries_controller.rb`
- `app/views/service_log_entries/_form.html.erb`
- `app/views/service_log_entries/new.html.erb`
- `app/views/service_log_entries/index.html.erb` (minimal, redirect target)
- `spec/factories/service_log_entries.rb`
- `spec/requests/service_log_entries_spec.rb`

Files to modify:
- `app/models/service_log_entry.rb` (add belongs_to :service_type, validations)
- `db/schema.rb` (auto-updated by migration)

Files to NOT touch:
- `app/models/service_type.rb` — global catalog, no changes needed
- `app/services/due_soon_calculator.rb` — Epic 4 concern
- `app/controllers/vehicles_controller.rb` — no changes needed
- `app/views/vehicles/show.html.erb` — Epic 3.3/4.3 will add due-soon section

### Previous Story Learnings (Story 3.1)

- The `service_types` table uses a **case-insensitive unique index** on `lower(name)`. The `ServiceType` model has presence + case-insensitive uniqueness validation. No changes to `ServiceType` are needed in this story.
- All 78 specs passed after Story 3.1. Run `bundle exec rspec` after implementing to confirm zero regressions.
- Factory pattern established: `spec/factories/service_types.rb` uses `FactoryBot.define { factory :service_type { name { "Engine Oil" } } }` — use `create(:service_type)` in service_log_entry factory.

### References

- Story ACs: `_bmad-output/planning-artifacts/epics.md#Story 3.2: Create Service Log Entry`
- Epic context: `_bmad-output/planning-artifacts/epics.md#Epic 3: Service History Logging`
- Schema: `_bmad-output/planning-artifacts/architecture.md#Data Architecture`
- Naming conventions: `_bmad-output/planning-artifacts/architecture.md#Naming Patterns`
- Auth pattern: `_bmad-output/planning-artifacts/architecture.md#Authentication & Security`
- Format patterns: `_bmad-output/planning-artifacts/architecture.md#Format Patterns`
- Controller structure: `_bmad-output/planning-artifacts/architecture.md#Structure Patterns`
- Existing routes: `config/routes.rb`
- Auth enforcement: `app/controllers/application_controller.rb`
- Request spec pattern: `spec/requests/vehicles_spec.rb`
- Vehicle factory pattern: `spec/factories/vehicles.rb`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4.6

### Debug Log References

### Completion Notes List

### File List
