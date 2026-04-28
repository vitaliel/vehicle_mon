# Story 2.4: Update Vehicle Mileage

Status: ready-for-dev

## Story

As an authenticated user,
I want to update my vehicle's current mileage at any time,
so that the app always reflects the vehicle's real odometer reading.

## Acceptance Criteria

1. **Given** I am on my vehicle's detail page, **When** I submit a mileage update with a valid integer value (≥ 0), **Then** the vehicle's `current_mileage` is updated **And** I am redirected back to the vehicle detail page with a `flash[:notice]` confirmation.
2. **Given** I submit a non-numeric or negative mileage value, **When** the form is submitted, **Then** I see a validation error and the change is rejected (form re-renders with `status: 422`).
3. **Given** another user's vehicle ID is in the URL, **When** the update request is submitted, **Then** I am redirected to root with a `flash[:alert]` (ARC10 — RecordNotFound rescue in ApplicationController).

## Tasks / Subtasks

- [ ] Task 1: Add `show` and `update_mileage` actions to VehiclesController (AC: #1, #2, #3)
  - [ ] Extend `before_action :set_vehicle` to include `:show` and `:update_mileage`.
  - [ ] Add `show` action (empty — `@vehicle` already set by `set_vehicle`).
  - [ ] Add `update_mileage` action: attempt `@vehicle.update(mileage_params)`, on success redirect to `vehicle_path(@vehicle)` with `flash[:notice]`, on failure re-render `show` with `status: :unprocessable_entity`.
  - [ ] Add private `mileage_params` method: `params.require(:vehicle).permit(:current_mileage)`.

- [ ] Task 2: Create `app/views/vehicles/show.html.erb` (AC: #1, #2)
  - [ ] Display vehicle details: year, make, model, current mileage (formatted with `number_with_delimiter`).
  - [ ] Include a mileage update form using `form_with(url: update_mileage_vehicle_path(@vehicle), method: :patch)` — do NOT use `model: @vehicle` (that would route to `vehicles#update`).
  - [ ] Show validation errors using `render 'devise/shared/error_messages', resource: @vehicle` inside the form.
  - [ ] Include a "Back" link to `vehicles_path`.

- [ ] Task 3: Add request specs for `show` and `update_mileage` (AC: #1–#3)
  - [ ] Add to `spec/requests/vehicles_spec.rb` (do NOT create a new file):
    - `GET /vehicles/:id` — unauthenticated → redirects to sign-in.
    - `GET /vehicles/:id` — authenticated, own vehicle → 200 OK.
    - `GET /vehicles/:id` — authenticated, other user's vehicle → redirects to root.
    - `PATCH /vehicles/:id/update_mileage` — unauthenticated → redirects to sign-in.
    - `PATCH /vehicles/:id/update_mileage` — authenticated, own vehicle, valid value → updates `current_mileage`, redirects to `vehicle_path`, `flash[:notice]` set.
    - `PATCH /vehicles/:id/update_mileage` — authenticated, own vehicle, invalid value (negative) → 422, mileage unchanged.
    - `PATCH /vehicles/:id/update_mileage` — authenticated, other user's vehicle → redirects to root.

## Dev Notes

### Architecture & Critical Constraints

- **Ownership scoping is MANDATORY** — `set_vehicle` uses `current_user.vehicles.find(params[:id])`. Never use bare `Vehicle.find`. [Source: architecture.md#Authentication & Security]
- **RecordNotFound auto-rescued** — `ApplicationController` rescues `ActiveRecord::RecordNotFound` → redirects to `root_path` with `flash[:alert]`. This covers AC #3 for free — do NOT add custom rescue logic.
- **Flash keys** — `flash[:notice]` for success, `flash[:alert]` for errors. NEVER `:success`, `:info`, `:error`, `:danger`. [Source: architecture.md#Format Patterns]
- **Mileage validation already in model** — `validates :current_mileage, numericality: { only_integer: true, greater_than_or_equal_to: 0 }`. No migration or model change needed.
- **`update_mileage` is a member route** — already defined as `member do patch :update_mileage end` in `config/routes.rb`. The helper is `update_mileage_vehicle_path(@vehicle)` → `PATCH /vehicles/:id/update_mileage`.
- **Minimal `show` page** — this story's show view covers vehicle info + mileage form only. Service history and due-soon status are deferred to Epics 3–5. Do NOT attempt to call `DueSoonCalculator` here.
- **`_vehicle_card` "View" link** — the `link_to "View", vehicle_path(vehicle)` button already exists in `app/views/shared/_vehicle_card.html.erb`. Once `show` is added, it will work automatically — no change to the partial is required.
- **Global auth** — `before_action :authenticate_user!` is in `ApplicationController`. No per-action auth needed.

### VehiclesController — Canonical Pattern

```ruby
class VehiclesController < ApplicationController
  before_action :set_vehicle, only: [:show, :edit, :update, :destroy, :update_mileage]

  def show
  end

  # ... existing index, new, create, edit, update, destroy ...

  def update_mileage
    if @vehicle.update(mileage_params)
      redirect_to vehicle_path(@vehicle), notice: "Mileage updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_vehicle
    @vehicle = current_user.vehicles.find(params[:id])
  end

  def vehicle_params
    params.require(:vehicle).permit(:make, :model, :year, :current_mileage)
  end

  def mileage_params
    params.require(:vehicle).permit(:current_mileage)
  end
end
```

### `show.html.erb` Structure

```erb
<div class="container py-4">
  <h1 class="mb-1"><%= @vehicle.year %> <%= @vehicle.make %> <%= @vehicle.model %></h1>
  <p class="text-muted mb-4">
    <i class="bi bi-speedometer2"></i>
    Current mileage: <strong><%= number_with_delimiter(@vehicle.current_mileage) %> km</strong>
  </p>

  <div class="card mb-4" style="max-width: 400px;">
    <div class="card-body">
      <h5 class="card-title">Update Mileage</h5>
      <%= form_with(url: update_mileage_vehicle_path(@vehicle), method: :patch) do |f| %>
        <%= render 'devise/shared/error_messages', resource: @vehicle %>
        <div class="mb-3">
          <%= f.label :current_mileage, "Current Mileage (km)", class: "form-label" %>
          <%= f.number_field :current_mileage,
                name: "vehicle[current_mileage]",
                value: @vehicle.current_mileage,
                class: "form-control",
                min: 0,
                required: true %>
        </div>
        <%= f.submit "Update Mileage", class: "btn btn-primary" %>
      <% end %>
    </div>
  </div>

  <%= link_to "← Back to Vehicles", vehicles_path, class: "btn btn-outline-secondary" %>
</div>
```

**Important:** Use `form_with(url: update_mileage_vehicle_path(@vehicle), method: :patch)` — explicit URL routing to the member action. If you used `form_with(model: @vehicle)`, Rails would route to `vehicles#update` instead, which would change ALL vehicle fields, not just mileage.

### Mileage Form Field Note

Use `name: "vehicle[current_mileage]"` explicitly to ensure the param nests under `params[:vehicle]` for `mileage_params`. When using `form_with(url:)` (non-model form), the `f.number_field` helper still wraps with `vehicle` prefix only if the form object is provided. Since we use `form_with(url:)` without a model, set `name:` explicitly.

### Request Spec Pattern (append to `spec/requests/vehicles_spec.rb`)

```ruby
describe "GET /vehicles/:id" do
  context "when unauthenticated" do
    it "redirects to sign-in" do
      vehicle = create(:vehicle)
      get vehicle_path(vehicle)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "when authenticated" do
    let(:user) { create(:user) }
    let(:vehicle) { create(:vehicle, user: user) }
    let(:other_user) { create(:user) }

    before { sign_in user }

    it "shows the vehicle detail page" do
      get vehicle_path(vehicle)
      expect(response).to have_http_status(:ok)
    end

    it "redirects to root for another user's vehicle" do
      other_vehicle = create(:vehicle, user: other_user)
      get vehicle_path(other_vehicle)
      expect(response).to redirect_to(root_path)
    end
  end
end

describe "PATCH /vehicles/:id/update_mileage" do
  context "when unauthenticated" do
    it "redirects to sign-in" do
      vehicle = create(:vehicle)
      patch update_mileage_vehicle_path(vehicle), params: { vehicle: { current_mileage: 60_000 } }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "when authenticated" do
    let(:user) { create(:user) }
    let(:vehicle) { create(:vehicle, user: user, current_mileage: 50_000) }
    let(:other_user) { create(:user) }

    before { sign_in user }

    it "updates mileage and redirects to vehicle_path with flash[:notice]" do
      patch update_mileage_vehicle_path(vehicle), params: { vehicle: { current_mileage: 60_000 } }
      expect(vehicle.reload.current_mileage).to eq(60_000)
      expect(response).to redirect_to(vehicle_path(vehicle))
      follow_redirect!
      expect(response.body).to include("Mileage updated successfully")
    end

    it "rejects a negative mileage and returns 422" do
      patch update_mileage_vehicle_path(vehicle), params: { vehicle: { current_mileage: -1 } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(vehicle.reload.current_mileage).to eq(50_000)
    end

    it "redirects to root for another user's vehicle" do
      other_vehicle = create(:vehicle, user: other_user)
      patch update_mileage_vehicle_path(other_vehicle), params: { vehicle: { current_mileage: 60_000 } }
      expect(response).to redirect_to(root_path)
    end
  end
end
```

### Routes (no changes needed)

`resources :vehicles` with `member do patch :update_mileage end` is already in `config/routes.rb`. Verify with:
```bash
rails routes | grep update_mileage
# → update_mileage_vehicle PATCH /vehicles/:id/update_mileage(.:format) vehicles#update_mileage
```

### Schema (no changes needed)

`current_mileage` column already exists on `vehicles` table (added in Story 2.1). No new migrations.

### Project Structure Notes

Files to create:
- `app/views/vehicles/show.html.erb` — minimal vehicle detail page with mileage update form

Files to modify:
- `app/controllers/vehicles_controller.rb` — extend `before_action :set_vehicle` to include `:show, :update_mileage`; add `show` action; add `update_mileage` action; add `mileage_params` private method
- `spec/requests/vehicles_spec.rb` — append 7 new specs (GET show × 3 + PATCH update_mileage × 4)

Files NOT to touch:
- `config/routes.rb` — already has both `resources :vehicles` and `patch :update_mileage` member route
- `db/migrate/` — no schema changes
- `app/models/vehicle.rb` — validation already present
- `app/views/shared/_vehicle_card.html.erb` — "View" link already points to `vehicle_path`; it will work once `show` is added

### Previous Story Intelligence (2.3)

- `spec/support/devise.rb` configured — use `sign_in user` in request specs.
- `spec/factories/vehicles.rb` exists with `association :user` — `create(:vehicle, user: user)` for owned, `create(:vehicle)` for other-user.
- `set_vehicle` uses `current_user.vehicles.find(params[:id])` — just extend `before_action` list.
- Bootstrap form styling convention: `form-control` on inputs, `btn btn-primary` on submit, `mb-3` spacing on field groups. [Source: story 2.2, 2.3]
- `number_with_delimiter` already used in `_vehicle_card` — use the same helper for mileage display in show.
- Existing spec file is `spec/requests/vehicles_spec.rb` — do NOT create a separate file.
- `ServiceLogEntry` and `ReminderThreshold` factories exist (used in Story 2.3 cascade spec) — not needed for this story.

### References

- Story requirements: `_bmad-output/planning-artifacts/epics.md#Story 2.4`
- Route definition: `config/routes.rb` (member route `patch :update_mileage`)
- Ownership scoping: `_bmad-output/planning-artifacts/architecture.md#Authentication & Security, #Process Patterns`
- Flash conventions: `_bmad-output/planning-artifacts/architecture.md#Format Patterns`
- Mileage validation: `app/models/vehicle.rb`
- Form pattern: `app/views/vehicles/_form.html.erb` (for Bootstrap class conventions)
- Prior story context: `_bmad-output/implementation-artifacts/2-3-delete-vehicle.md`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4.6

### Debug Log References

### Completion Notes List

### File List

## Change Log

- 2026-04-28: Story 2.4 created — Update Vehicle Mileage context prepared for development.
