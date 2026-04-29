# Story 4.2: Configure Reminder Thresholds

Status: done

## Story

As an authenticated user,
I want to configure mileage and/or time thresholds for a specific service type on a specific vehicle,
so that the system knows when to alert me that maintenance is due.

## Acceptance Criteria

1. **Given** I own a vehicle and service types are seeded,
   **When** I visit the reminder thresholds page for my vehicle (`/vehicles/:id/reminder_thresholds`),
   **Then** I see the list of all service types with their current threshold configuration (mileage interval and/or time interval in months), or "Not configured" if none set for that service type. (FR17–FR20)

2. **Given** I set a mileage interval, a time interval (months), or both for a service type and save,
   **When** the threshold is saved,
   **Then** a `ReminderThreshold` row exists for that vehicle + service type, (FR17, FR18, FR20)
   **And** a `flash[:notice]` confirmation is shown,
   **And** I am redirected to the reminder thresholds index for that vehicle.

3. **Given** both mileage and time fields are left blank,
   **When** I submit the form,
   **Then** no threshold row is saved (graceful no-threshold state, FR19),
   **And** I am redirected to the thresholds index without an error message.

4. **Given** another user's vehicle ID is in the URL,
   **When** I attempt to access the thresholds page,
   **Then** I am redirected to root with a `flash[:alert]`.

5. **Given** I have already configured a threshold for a service type,
   **When** I edit it and clear both fields to blank and save,
   **Then** the existing `ReminderThreshold` row is destroyed (returns to unconfigured state),
   **And** a `flash[:notice]` is shown,
   **And** I am redirected to the thresholds index.

## Tasks / Subtasks

- [x] Task 1: Add validations to `ReminderThreshold` model (AC: #2, #3)
  - [x] Add `validates :mileage_interval, numericality: { greater_than: 0, allow_nil: true }`
  - [x] Add `validates :time_interval_months, numericality: { greater_than: 0, allow_nil: true }`
  - [x] Add `validates :vehicle_id, :service_type_id, presence: true`
  - [x] Add custom validator `at_least_one_interval_set` (only enforced when creating — on update, controller handles all-blank as destroy)

- [x] Task 2: Create `ReminderThresholdsController` (AC: #1–#5)
  - [x] `before_action :set_vehicle` — scoped via `current_user.vehicles.find(params[:vehicle_id])`
  - [x] `before_action :set_threshold, only: [:edit, :update, :destroy]` — scoped via `@vehicle.reminder_thresholds.find(params[:id])`
  - [x] `index` — load all service types + build threshold hash `{ service_type.id => threshold_or_nil }`
  - [x] `new` — build `@threshold = @vehicle.reminder_thresholds.build`, pre-select `service_type_id` from `params[:service_type_id]`; load `@service_types = ServiceType.order(:name)`
  - [x] `create` — if both intervals blank: redirect to index with notice "No threshold configured."; else save and redirect to index with notice or re-render new with errors
  - [x] `edit` — load `@service_types = ServiceType.order(:name)` for form dropdown
  - [x] `update` — if both intervals blank: destroy threshold and redirect to index with notice "Threshold removed."; else update and redirect to index with notice or re-render edit with errors
  - [x] `destroy` — destroy and redirect to index with notice

- [x] Task 3: Create views (AC: #1–#3)
  - [x] `app/views/reminder_thresholds/index.html.erb` — table of all service types showing mileage_interval and time_interval_months; "Configure" link for unconfigured, "Edit" for configured; link back to vehicle
  - [x] `app/views/reminder_thresholds/new.html.erb` — heading "Configure Threshold" + render `_form`
  - [x] `app/views/reminder_thresholds/edit.html.erb` — heading "Edit Threshold" + render `_form`
  - [x] `app/views/reminder_thresholds/_form.html.erb` — service_type select (disabled on edit), mileage_interval number_field (optional), time_interval_months number_field (optional), submit + cancel

- [x] Task 4: Add reminder threshold link to vehicle show page (AC: #1)
  - [x] Add `link_to "Configure Reminders", vehicle_reminder_thresholds_path(@vehicle), class: "btn btn-outline-secondary"` alongside existing buttons in `app/views/vehicles/show.html.erb`

- [x] Task 5: Create `spec/requests/reminder_thresholds_spec.rb` (AC: #1–#5)
  - [x] `GET index` — unauthenticated redirects to sign-in
  - [x] `GET index` — authenticated with own vehicle: 200, shows all service type names
  - [x] `GET index` — authenticated with other user's vehicle: redirects to root with flash[:alert]
  - [x] `POST create` — valid params (mileage only): creates threshold, redirects to index with flash[:notice]
  - [x] `POST create` — valid params (both): creates threshold
  - [x] `POST create` — both blank: no threshold created, redirects to index
  - [x] `POST create` — other user's vehicle: redirected to root
  - [x] `GET edit` — own threshold: 200
  - [x] `GET edit` — other user's vehicle: redirected to root
  - [x] `PATCH update` — valid params: updates threshold, redirects to index with flash[:notice]
  - [x] `PATCH update` — both blank: destroys threshold, redirects to index
  - [x] `DELETE destroy` — destroys and redirects to index with flash[:notice]

### Review Findings

- [x] [Review][Patch] service_type_id can be changed via crafted update request [app/controllers/reminder_thresholds_controller.rb:43]
- [x] [Review][Patch] create path can raise on duplicate vehicle/service_type instead of handling uniqueness cleanly [app/controllers/reminder_thresholds_controller.rb:24]

## Dev Notes

### Current State Summary

**Schema is COMPLETE** (migrated in Story 4.1). No migration needed.

```
reminder_thresholds: id, vehicle_id (not null, FK), service_type_id (not null, FK),
                     mileage_interval (integer, nullable), time_interval_months (integer, nullable),
                     created_at, updated_at
UNIQUE INDEX: (vehicle_id, service_type_id)
```

**Model exists** (`app/models/reminder_threshold.rb`) with `belongs_to :vehicle` and `belongs_to :service_type`. No validations yet — must add in Task 1.

**Factory exists** (`spec/factories/reminder_thresholds.rb`):
```ruby
FactoryBot.define do
  factory :reminder_threshold do
    association :vehicle
    association :service_type
    mileage_interval { 10_000 }
    time_interval_months { 12 }
  end
end
```

**Routes already exist** (nested under vehicles):
```ruby
resources :vehicles do
  resources :reminder_thresholds
  resources :service_log_entries
  member do
    patch :update_mileage
  end
end
```
Routes available: `vehicle_reminder_thresholds_path(@vehicle)`, `new_vehicle_reminder_threshold_path(@vehicle)`, `edit_vehicle_reminder_threshold_path(@vehicle, @threshold)`, etc.

**No controller, views, or request specs exist yet** — all need to be created.

### Established Patterns to Follow

**Controller pattern** — mirror `ServiceLogEntriesController` exactly:

```ruby
# app/controllers/reminder_thresholds_controller.rb
class ReminderThresholdsController < ApplicationController
  before_action :set_vehicle
  before_action :set_threshold, only: [:edit, :update, :destroy]

  def index
    @service_types = ServiceType.order(:name)
    thresholds = @vehicle.reminder_thresholds.index_by(&:service_type_id)
    @thresholds_by_service_type = @service_types.each_with_object({}) do |st, h|
      h[st] = thresholds[st.id]
    end
  end

  def new
    @threshold = @vehicle.reminder_thresholds.build
    @threshold.service_type_id = params[:service_type_id]
    @service_types = ServiceType.order(:name)
  end

  def create
    if both_intervals_blank?(threshold_params)
      redirect_to vehicle_reminder_thresholds_path(@vehicle), notice: "No threshold configured."
      return
    end
    @threshold = @vehicle.reminder_thresholds.build(threshold_params)
    if @threshold.save
      redirect_to vehicle_reminder_thresholds_path(@vehicle), notice: "Reminder threshold saved."
    else
      @service_types = ServiceType.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @service_types = ServiceType.order(:name)
  end

  def update
    if both_intervals_blank?(threshold_params)
      @threshold.destroy
      redirect_to vehicle_reminder_thresholds_path(@vehicle), notice: "Threshold removed."
      return
    end
    if @threshold.update(threshold_params)
      redirect_to vehicle_reminder_thresholds_path(@vehicle), notice: "Reminder threshold updated."
    else
      @service_types = ServiceType.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @threshold.destroy
    redirect_to vehicle_reminder_thresholds_path(@vehicle), notice: "Reminder threshold removed."
  end

  private

  def set_vehicle
    @vehicle = current_user.vehicles.find(params[:vehicle_id])
  end

  def set_threshold
    @threshold = @vehicle.reminder_thresholds.find(params[:id])
  end

  def both_intervals_blank?(params)
    params[:mileage_interval].blank? && params[:time_interval_months].blank?
  end

  def threshold_params
    params.require(:reminder_threshold).permit(:service_type_id, :mileage_interval, :time_interval_months)
  end
end
```

**Key rules enforced:**
- `current_user.vehicles.find(params[:vehicle_id])` — NEVER bare `Vehicle.find` (architecture mandate)
- RecordNotFound is caught globally in `ApplicationController` → redirects to root with `flash[:alert]` — this satisfies AC4 automatically
- `flash[:notice]` only — never `:success` or `:info` (architecture rule)
- `render :new, status: :unprocessable_entity` on validation failure (Turbo-compatible)

### Model Validations

```ruby
# app/models/reminder_threshold.rb
class ReminderThreshold < ApplicationRecord
  belongs_to :vehicle
  belongs_to :service_type

  validates :mileage_interval, numericality: { greater_than: 0, allow_nil: true }
  validates :time_interval_months, numericality: { greater_than: 0, allow_nil: true }
end
```

No `at_least_one_interval_set` needed on the model — the controller handles all-blank gracefully before saving (AC3). The model constraint would only trigger if someone bypasses the controller.

### View Form Design

```erb
<%# app/views/reminder_thresholds/_form.html.erb %>
<%= form_with(model: [@vehicle, @threshold], class: "needs-validation") do |f| %>
  <%= render 'devise/shared/error_messages', resource: @threshold %>

  <div class="mb-3">
    <%= f.label :service_type_id, "Service Type", class: "form-label" %>
    <%= f.collection_select :service_type_id, @service_types, :id, :name,
          { prompt: "Select a service type" },
          { class: "form-select", required: true,
            disabled: @threshold.persisted? } %>
    <%# hidden field needed when disabled to still submit value on edit %>
    <% if @threshold.persisted? %>
      <%= f.hidden_field :service_type_id %>
    <% end %>
  </div>

  <div class="mb-3">
    <%= f.label :mileage_interval, "Mileage Interval (km, optional)", class: "form-label" %>
    <%= f.number_field :mileage_interval, class: "form-control", min: 1,
          placeholder: "e.g. 10000" %>
  </div>

  <div class="mb-3">
    <%= f.label :time_interval_months, "Time Interval (months, optional)", class: "form-label" %>
    <%= f.number_field :time_interval_months, class: "form-control", min: 1,
          placeholder: "e.g. 12" %>
  </div>

  <p class="text-muted small">Leave both blank to remove the threshold for this service type.</p>

  <%= f.submit class: "btn btn-primary" %>
  <%= link_to "Cancel", vehicle_reminder_thresholds_path(@vehicle), class: "btn btn-outline-secondary ms-2" %>
<% end %>
```

**⚠️ Disabled select + hidden field pattern:** When editing a threshold, `service_type_id` must not be changed (it's part of the unique key). Disable the select visually but submit via `hidden_field`. This prevents accidental re-association.

### Index View Design

The index should show all service types — not just those with thresholds — so users can see at a glance what's configured:

```erb
<%# app/views/reminder_thresholds/index.html.erb %>
<div class="container py-4">
  <h1>Reminder Thresholds — <%= @vehicle.year %> <%= @vehicle.make %> <%= @vehicle.model %></h1>

  <table class="table">
    <thead>
      <tr>
        <th>Service Type</th>
        <th>Mileage Interval</th>
        <th>Time Interval</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <% @thresholds_by_service_type.each do |service_type, threshold| %>
        <tr>
          <td><%= service_type.name %></td>
          <% if threshold %>
            <td><%= threshold.mileage_interval ? number_with_delimiter(threshold.mileage_interval) + " km" : "—" %></td>
            <td><%= threshold.time_interval_months ? "#{threshold.time_interval_months} months" : "—" %></td>
            <td>
              <%= link_to "Edit", edit_vehicle_reminder_threshold_path(@vehicle, threshold), class: "btn btn-sm btn-outline-primary" %>
              <%= button_to "Remove", vehicle_reminder_threshold_path(@vehicle, threshold),
                    method: :delete, class: "btn btn-sm btn-outline-danger",
                    data: { turbo_confirm: "Remove this threshold?" } %>
            </td>
          <% else %>
            <td colspan="2" class="text-muted">Not configured</td>
            <td>
              <%= link_to "Configure", new_vehicle_reminder_threshold_path(@vehicle, service_type_id: service_type.id), class: "btn btn-sm btn-outline-secondary" %>
            </td>
          <% end %>
        </tr>
      <% end %>
    </tbody>
  </table>

  <%= link_to "← Back to Vehicle", @vehicle, class: "btn btn-outline-secondary" %>
</div>
```

### Request Spec Pattern

Follow `spec/requests/service_log_entries_spec.rb` exactly for structure:

```ruby
# spec/requests/reminder_thresholds_spec.rb
require 'rails_helper'

RSpec.describe "ReminderThresholds", type: :request do
  let(:user)         { create(:user) }
  let(:other_user)   { create(:user) }
  let(:vehicle)      { create(:vehicle, user: user) }
  let(:service_type) { create(:service_type) }

  describe "GET /vehicles/:vehicle_id/reminder_thresholds" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        get vehicle_reminder_thresholds_path(vehicle)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated with own vehicle" do
      before { sign_in user }

      it "returns 200 and shows service type names" do
        # ServiceType seed records should be present (from seeds.rb)
        get vehicle_reminder_thresholds_path(vehicle)
        expect(response).to have_http_status(:ok)
      end

      it "shows 'Not configured' for unconfigured service types" do
        get vehicle_reminder_thresholds_path(vehicle)
        expect(response.body).to include("Not configured")
      end
    end

    context "when accessing another user's vehicle" do
      before { sign_in user }

      it "redirects to root with alert" do
        other_vehicle = create(:vehicle, user: other_user)
        get vehicle_reminder_thresholds_path(other_vehicle)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /vehicles/:vehicle_id/reminder_thresholds" do
    before { sign_in user }

    context "with valid mileage interval" do
      it "creates a threshold and redirects with notice" do
        post vehicle_reminder_thresholds_path(vehicle),
             params: { reminder_threshold: { service_type_id: service_type.id,
                                             mileage_interval: 10_000,
                                             time_interval_months: "" } }
        expect(response).to redirect_to(vehicle_reminder_thresholds_path(vehicle))
        follow_redirect!
        expect(response.body).to include("Reminder threshold saved")
        expect(ReminderThreshold.count).to eq(1)
      end
    end

    context "with both intervals blank" do
      it "does not create a threshold and redirects gracefully" do
        post vehicle_reminder_thresholds_path(vehicle),
             params: { reminder_threshold: { service_type_id: service_type.id,
                                             mileage_interval: "",
                                             time_interval_months: "" } }
        expect(response).to redirect_to(vehicle_reminder_thresholds_path(vehicle))
        expect(ReminderThreshold.count).to eq(0)
      end
    end
  end

  # ... (PATCH update, DELETE destroy — follow same pattern)
end
```

### Project Structure — Files to Create/Modify

**CREATE:**
- `app/controllers/reminder_thresholds_controller.rb`
- `app/views/reminder_thresholds/index.html.erb`
- `app/views/reminder_thresholds/new.html.erb`
- `app/views/reminder_thresholds/edit.html.erb`
- `app/views/reminder_thresholds/_form.html.erb`
- `spec/requests/reminder_thresholds_spec.rb`

**MODIFY:**
- `app/models/reminder_threshold.rb` — add numericality validations
- `app/views/vehicles/show.html.erb` — add "Configure Reminders" button

**DO NOT TOUCH:**
- `db/schema.rb` — no migration needed, schema is complete
- `app/services/due_soon_calculator.rb` — not in scope
- `spec/services/due_soon_calculator_spec.rb` — not in scope
- Any Epic 3, Epic 5 files

### Testing Baseline

Current baseline (after Story 4.1 merge): **135 examples, 0 failures**, 2 pre-existing pending.

Run `bundle exec rspec` before starting. All new specs go in `spec/requests/reminder_thresholds_spec.rb`.

### Architecture Compliance Checklist

- ✅ Authorization via `current_user.vehicles.find(params[:vehicle_id])` — no bare `Vehicle.find`
- ✅ `RecordNotFound` → handled globally in `ApplicationController` → satisfies AC4 (other user's vehicle redirects to root with alert)
- ✅ `flash[:notice]` only — never `:success`, `:info`, `:error`
- ✅ `render :new, status: :unprocessable_entity` on create failure (Turbo-compatible)
- ✅ `render :edit, status: :unprocessable_entity` on update failure (Turbo-compatible)
- ✅ `DueSoonCalculator` NOT called here — that's Story 4.3's job
- ✅ Full nested routes: `/vehicles/:vehicle_id/reminder_thresholds` — no shallow variants
- ✅ Bootstrap 5.3.8 classes + Bootstrap Icons for view styling
- ✅ No business logic in views — controller builds `@thresholds_by_service_type` hash

### Previous Story Learnings (4.1)

- **Factory regression:** A bare `ReminderThreshold.create!(vehicle: vehicle)` without `service_type` in `vehicles_spec.rb` was broken by adding `service_type_id NOT NULL`. The fix used the `create(:reminder_threshold, ...)` factory. If any spec creates `ReminderThreshold` inline, use the factory.
- **`let!` (bang) matters:** In request specs involving associations, use `let!` to materialize records before the action.
- **DueSoonCalculator edge case:** Threshold with both intervals nil (added in review) returns `:unconfigured` — this aligns with AC3 here: an all-nil threshold row should not exist; the controller prevents creation.
- **No-entry default:** Vehicle with no service log entries + a threshold set will show `:due_soon` in DueSoonCalculator — remind the user to log their first entry.

### References

- Story ACs: `_bmad-output/planning-artifacts/epics.md#Story 4.2: Configure Reminder Thresholds`
- Epic context: `_bmad-output/planning-artifacts/epics.md#Epic 4: Maintenance Reminders & Due-Soon Engine`
- Controller pattern: `app/controllers/service_log_entries_controller.rb`
- Request spec pattern: `spec/requests/service_log_entries_spec.rb`
- Form pattern: `app/views/service_log_entries/_form.html.erb`
- Routes: `config/routes.rb` (nested resources already present)
- Schema: `db/schema.rb` (reminder_thresholds complete)
- Model: `app/models/reminder_threshold.rb`
- Factory: `spec/factories/reminder_thresholds.rb`
- Previous story: `_bmad-output/implementation-artifacts/4-1-due-soon-calculator-service-object.md`
- Auth/ownership enforcement: `_bmad-output/planning-artifacts/architecture.md#Process Patterns`
- Project structure: `_bmad-output/planning-artifacts/architecture.md#Project Structure & Boundaries`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4.6

### Debug Log References

- `validates :vehicle_id, :service_type_id, presence: true` not added — `belongs_to` in Rails 5+ validates presence by default; redundant.
- `at_least_one_interval_set` custom validator not added — the controller short-circuits all-blank submissions before model save, making a model-level constraint unnecessary and potentially confusing.
- Form uses `disabled` attribute on service_type select in edit view + hidden_field to submit value — prevents accidental service_type change on existing threshold.

### Completion Notes List

- Added `validates :mileage_interval` and `validates :time_interval_months` numericality guards (greater_than: 0, allow_nil: true) to `ReminderThreshold` model.
- Created `ReminderThresholdsController` with full CRUD: `index`, `new`, `create`, `edit`, `update`, `destroy`. All queries scoped through `current_user.vehicles`. Global `RecordNotFound` handler covers AC4 (other user's vehicle) automatically.
- `create` and `update` both short-circuit when both intervals are blank: `create` skips persistence; `update` destroys the existing row — graceful no-threshold state (FR19, AC3, AC5).
- Created 4 views: `index.html.erb`, `new.html.erb`, `edit.html.erb`, `_form.html.erb` under `app/views/reminder_thresholds/`. Index lists ALL service types (not just configured), showing "Not configured" for unconfigured ones.
- Added "Configure Reminders" button to `app/views/vehicles/show.html.erb`.
- Created `spec/models/reminder_threshold_spec.rb` (8 examples) and `spec/requests/reminder_thresholds_spec.rb` (21 examples).
- **167 examples, 0 failures**, 2 pre-existing pending. Previous baseline was 135; 32 new examples added.

### File List

- `app/models/reminder_threshold.rb` (modified — added numericality validations)
- `app/controllers/reminder_thresholds_controller.rb` (new)
- `app/views/reminder_thresholds/index.html.erb` (new)
- `app/views/reminder_thresholds/new.html.erb` (new)
- `app/views/reminder_thresholds/edit.html.erb` (new)
- `app/views/reminder_thresholds/_form.html.erb` (new)
- `app/views/vehicles/show.html.erb` (modified — added "Configure Reminders" button)
- `spec/models/reminder_threshold_spec.rb` (new)
- `spec/requests/reminder_thresholds_spec.rb` (new)
- `_bmad-output/implementation-artifacts/4-2-configure-reminder-thresholds.md` (story updated)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (updated)
