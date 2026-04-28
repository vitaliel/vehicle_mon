# Story 3.4: Edit Service Log Entry

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an authenticated user,
I want to edit an existing service log entry,
so that I can correct mistakes after saving.

## Acceptance Criteria

1. **Given** I own a service log entry, **When** I visit its edit form, **Then** all fields are pre-filled with the current values.

2. **Given** I submit valid changes, **When** the form is saved, **Then** the entry is updated and a `flash[:notice]` confirmation is shown, and I am redirected to the service history index for that vehicle.

3. **Given** I submit with a required field cleared, **When** the form is submitted, **Then** I see a validation error and the form re-renders with `status: 422`.

4. **Given** another user's entry ID is in the URL, **When** I attempt to access the edit page or submit an update, **Then** I am redirected to root with a `flash[:alert]`.

## Tasks / Subtasks

- [x] Task 1: Add `edit` and `update` actions to `ServiceLogEntriesController` (AC: #1, #2, #3, #4)
  - [x] Add `before_action :set_entry, only: [:edit, :update]` using `@vehicle.service_log_entries.find(params[:id])`
  - [x] Add `edit` action (no body needed — just `set_entry` loads `@entry`; populate `@service_types`)
  - [x] Add `update` action: on success redirect to `vehicle_service_log_entries_path(@vehicle)` with `notice:`; on failure render `:edit` with `status: :unprocessable_entity` and reload `@service_types`

- [x] Task 2: Create `app/views/service_log_entries/edit.html.erb` (AC: #1)
  - [x] Mirror `new.html.erb` structure: container, heading "Edit Service Entry", vehicle sub-heading, render `'form'` partial with `vehicle: @vehicle, entry: @entry`

- [x] Task 3: Add "Edit" link in the service history index table (AC: #1)
  - [x] In `app/views/service_log_entries/index.html.erb`, add an "Actions" column to the table header and a cell per row with `link_to "Edit", edit_vehicle_service_log_entry_path(@vehicle, entry), class: "btn btn-sm btn-outline-secondary"`

- [x] Task 4: Write request specs (AC: #1, #2, #3, #4)
  - [x] `GET /vehicles/:vehicle_id/service_log_entries/:id/edit` — 200 with pre-filled values (check key field values appear in body)
  - [x] `PATCH /vehicles/:vehicle_id/service_log_entries/:id` with valid params — redirects to index with `flash[:notice]`
  - [x] `PATCH` with invalid params (blank `serviced_on`) — 422 re-render
  - [x] `GET edit` and `PATCH` with another user's entry — redirect to root + `flash[:alert]`

## Dev Notes

### Controller Changes (MOST IMPORTANT)

The current `ServiceLogEntriesController` only has `index`, `new`, `create`. You must add `edit`, `update`, and a `set_entry` before_action.

**Required diff (add these to the controller):**

```ruby
class ServiceLogEntriesController < ApplicationController
  before_action :set_vehicle
  before_action :set_entry, only: [:edit, :update]   # ADD THIS

  # existing actions unchanged …

  def edit                                            # ADD THIS
    @service_types = ServiceType.order(:name)
  end

  def update                                          # ADD THIS
    if @entry.update(entry_params)
      redirect_to vehicle_service_log_entries_path(@vehicle), notice: "Service entry updated successfully."
    else
      @service_types = ServiceType.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_vehicle
    @vehicle = current_user.vehicles.find(params[:vehicle_id])
  end

  def set_entry                                       # ADD THIS
    @entry = @vehicle.service_log_entries.find(params[:id])
  end

  def entry_params
    params.require(:service_log_entry).permit(
      :service_type_id, :serviced_on, :mileage_at_service,
      :service_center, :parts_cost, :labour_cost, :notes
    )
  end
end
```

**Authorization is automatic** — `@vehicle.service_log_entries.find(params[:id])` raises `ActiveRecord::RecordNotFound` when the entry doesn't belong to the vehicle, which belongs to `current_user`. `ApplicationController#handle_not_found` redirects to root with `alert: "Record not found."`. Do NOT add a separate rescue block.

### View: edit.html.erb

The `_form.html.erb` partial already uses `form_with(model: [@vehicle, @entry])` which auto-selects `PATCH` for persisted records and `POST` for new ones. Reusing it is correct.

```erb
<%# app/views/service_log_entries/edit.html.erb %>
<div class="container py-4">
  <h1 class="mb-4">Edit Service Entry</h1>
  <h5 class="text-muted mb-4"><%= @vehicle.year %> <%= @vehicle.make %> <%= @vehicle.model %></h5>

  <%= render 'form', vehicle: @vehicle, entry: @entry %>
</div>
```

### View: Index Table — Add Edit Link

The `index.html.erb` table currently has no actions column. Add one:

```erb
<%# In <thead><tr> — add after Notes %>
<th>Actions</th>

<%# In <tbody><tr> — add after notes cell %>
<td>
  <%= link_to "Edit", edit_vehicle_service_log_entry_path(@vehicle, entry),
        class: "btn btn-sm btn-outline-secondary" %>
</td>
```

### Routing (Already Configured — No Changes Needed)

```ruby
resources :vehicles do
  resources :service_log_entries   # ← already in config/routes.rb
end
```

This already generates `edit_vehicle_service_log_entry_path(@vehicle, @entry)` → `GET /vehicles/:vehicle_id/service_log_entries/:id/edit` and `PATCH /vehicles/:vehicle_id/service_log_entries/:id`.

### Flash Keys (Must Follow)

- Success redirect: `flash[:notice]` only — use `"Service entry updated successfully."`
- Auth/not-found redirect: `flash[:alert]` only (set automatically by `handle_not_found`)

[Source: _bmad-output/planning-artifacts/architecture.md#Format Patterns]

### Validation Rules (From Model — Must Not Duplicate)

The `ServiceLogEntry` model already validates:

| Field | Validation |
|-------|-----------|
| `service_type` | presence: true |
| `serviced_on` | presence: true |
| `mileage_at_service` | numericality, integer, ≥ 0 |
| `service_center` | presence: true |
| `parts_cost` | numericality, ≥ 0 |
| `labour_cost` | numericality, ≥ 0 |

Do NOT add any validations to the controller. The model handles it.

### Existing Shared Partial: `_form.html.erb`

Already at `app/views/service_log_entries/_form.html.erb`. It:
- Uses `form_with(model: [@vehicle, @entry])` — works for both new and edit
- Renders `devise/shared/error_messages` for validation errors
- Includes a "Cancel" link → `vehicle_service_log_entries_path(@vehicle)`
- Has all required fields: service_type_id, serviced_on, mileage_at_service, service_center, parts_cost, labour_cost, notes

**Do NOT modify `_form.html.erb`** — it is correct as-is.

### Factory Reference (For Specs)

```ruby
create(:service_log_entry,
  vehicle: vehicle,
  service_type: service_type,
  serviced_on: Date.new(2025, 4, 23),
  mileage_at_service: 50_000,
  service_center: "Quick Lube",
  parts_cost: 25.00,
  labour_cost: 50.00,
  notes: "Checked brakes"
)
```

All fields required at DB level. Default factory has sensible values — only override what the test needs.

### Request Specs Pattern (Match Existing File)

Add within the existing `spec/requests/service_log_entries_spec.rb`. Follow the established pattern:

```ruby
let(:entry) { create(:service_log_entry, vehicle: vehicle, service_type: service_type) }

describe "GET /vehicles/:vehicle_id/service_log_entries/:id/edit" do
  context "when unauthenticated" do
    it "redirects to sign-in" do
      get edit_vehicle_service_log_entry_path(vehicle, entry)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "when authenticated as owner" do
    before { sign_in user }

    it "returns 200 with pre-filled field values" do
      get edit_vehicle_service_log_entry_path(vehicle, entry)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(entry.service_center)
    end

    it "redirects to root when accessing another user's entry" do
      other_vehicle = create(:vehicle, user: other_user)
      other_entry = create(:service_log_entry, vehicle: other_vehicle, service_type: service_type)
      get edit_vehicle_service_log_entry_path(other_vehicle, other_entry)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end
end

describe "PATCH /vehicles/:vehicle_id/service_log_entries/:id" do
  let(:valid_update) do
    { service_log_entry: { service_center: "New Center", serviced_on: Date.today,
                           mileage_at_service: 55_000, service_type_id: service_type.id,
                           parts_cost: 30.00, labour_cost: 60.00 } }
  end

  context "when unauthenticated" do
    it "redirects to sign-in" do
      patch vehicle_service_log_entry_path(vehicle, entry), params: valid_update
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "when authenticated with valid params" do
    before { sign_in user }

    it "updates the entry and redirects with flash[:notice]" do
      patch vehicle_service_log_entry_path(vehicle, entry), params: valid_update
      expect(response).to redirect_to(vehicle_service_log_entries_path(vehicle))
      expect(flash[:notice]).to eq("Service entry updated successfully.")
      expect(entry.reload.service_center).to eq("New Center")
    end
  end

  context "when authenticated with invalid params (blank serviced_on)" do
    before { sign_in user }

    it "re-renders edit with status 422" do
      patch vehicle_service_log_entry_path(vehicle, entry),
            params: { service_log_entry: { serviced_on: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when accessing another user's entry (cross-user)" do
    before { sign_in user }

    it "redirects to root with flash[:alert]" do
      other_vehicle = create(:vehicle, user: other_user)
      other_entry = create(:service_log_entry, vehicle: other_vehicle, service_type: service_type)
      patch vehicle_service_log_entry_path(other_vehicle, other_entry), params: valid_update
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end
end
```

### Testing Standards

- Run `bundle exec rspec` before and after changes — must stay at **0 failures** (currently 107 specs pass, 2 pre-existing pending stubs).
- Add specs to the existing `spec/requests/service_log_entries_spec.rb` — do NOT create a new file.
- Use `sign_in user` (Devise test helpers, configured in `spec/rails_helper.rb`).
- All spec examples use `let` + `before { sign_in user }` — no instance variable pollution.

### Project Structure Notes

**Files to CREATE:**
- `app/views/service_log_entries/edit.html.erb` — edit page shell (thin wrapper around `_form`)

**Files to MODIFY:**
- `app/controllers/service_log_entries_controller.rb` — add `set_entry`, `edit`, `update`
- `app/views/service_log_entries/index.html.erb` — add Actions column with edit link
- `spec/requests/service_log_entries_spec.rb` — add edit/update specs

**Files to NOT touch:**
- `app/views/service_log_entries/_form.html.erb` — already correct for edit
- `app/models/service_log_entry.rb` — no model changes needed
- `app/models/service_type.rb` — global catalog, untouched
- `config/routes.rb` — `resources :service_log_entries` already covers edit/update
- Any Epic 4 files — out of scope

### Previous Story Learnings (Story 3.3)

- 107 specs pass (0 failures, 2 pre-existing pending stubs) — run `bundle exec rspec` before starting to confirm baseline.
- Flash key: always `flash[:notice]` (success) and `flash[:alert]` (error/redirect).
- `create(:service_type)` defaults to name `"Engine Oil"` — specify `name:` when testing name-dependent display.
- Cross-user protection is **free** via `current_user.vehicles.find` + `@vehicle.service_log_entries.find` — the double-scoping means both wrong vehicle_id AND wrong entry_id are automatically blocked.
- `sign_in user` via Devise helpers — no session manipulation needed.

### References

- Story ACs: `_bmad-output/planning-artifacts/epics.md#Story 3.4: Edit Service Log Entry`
- Epic context: `_bmad-output/planning-artifacts/epics.md#Epic 3: Service History Logging`
- Architecture patterns: `_bmad-output/planning-artifacts/architecture.md#Process Patterns`
- Auth pattern: `_bmad-output/planning-artifacts/architecture.md#Authentication & Security`
- Existing controller: `app/controllers/service_log_entries_controller.rb`
- Existing form partial: `app/views/service_log_entries/_form.html.erb`
- Existing index view: `app/views/service_log_entries/index.html.erb`
- Existing specs: `spec/requests/service_log_entries_spec.rb`
- Auth enforcement: `app/controllers/application_controller.rb`
- Routes: `config/routes.rb`
- Vehicles controller (edit/update pattern reference): `app/controllers/vehicles_controller.rb`

### Review Findings

- [x] [Review][Patch] Test verifies only one pre-filled field (`service_center`) for AC#1 — spec says "check key field values appear in body" [spec/requests/service_log_entries_spec.rb]
- [x] [Review][Patch] Invalid-params test does not assert error message appears in body for AC#3 — only checks `status: 422`, not that a validation error is rendered [spec/requests/service_log_entries_spec.rb]
- [x] [Review][Defer] No optimistic locking on concurrent edits [app/controllers/service_log_entries_controller.rb] — deferred, pre-existing
- [x] [Review][Defer] `mileage_at_service` blank submission coerced to nil (model has numericality but no presence validator) [app/models/service_log_entry.rb] — deferred, pre-existing

## Dev Agent Record

### Agent Model Used

claude-sonnet-4.6

### Debug Log References

- Routes were restricted to `only: [:index, :new, :create]` — added `:edit, :update` to `config/routes.rb`. Architecture doc implied full CRUD but the existing routes file had explicit `only:` restriction.

### Completion Notes List

- Added `before_action :set_entry, only: [:edit, :update]` to `ServiceLogEntriesController` using `@vehicle.service_log_entries.find(params[:id])` — cross-user protection is automatic via the double-scoped ownership chain.
- Added `edit` action (loads `@service_types`) and `update` action (success → redirect to index with `flash[:notice]`; failure → render `:edit` with 422 + reload `@service_types`).
- Created `app/views/service_log_entries/edit.html.erb` — thin wrapper reusing existing `_form.html.erb` partial (no partial changes needed).
- Added "Actions" column header and per-row "Edit" button to `app/views/service_log_entries/index.html.erb`.
- Updated `config/routes.rb`: added `:edit, :update` to service_log_entries resource.
- Added 7 new request specs (edit GET + PATCH covering: owner access, pre-fill, valid update, 422 on invalid, cross-user protection for both verbs).
- **114 specs pass, 0 failures**, 2 pre-existing pending stubs unchanged.

### File List

- `app/controllers/service_log_entries_controller.rb` (modified — added set_entry, edit, update)
- `app/views/service_log_entries/edit.html.erb` (created)
- `app/views/service_log_entries/index.html.erb` (modified — added Actions column + edit link)
- `config/routes.rb` (modified — added :edit, :update to service_log_entries)
- `spec/requests/service_log_entries_spec.rb` (modified — added edit/update specs)
- `_bmad-output/implementation-artifacts/3-4-edit-service-log-entry.md` (story updated)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (updated)
