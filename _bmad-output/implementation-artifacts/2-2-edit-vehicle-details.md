# Story 2.2: Edit Vehicle Details

Status: done

## Story

As an authenticated user,
I want to edit any of my vehicle's details,
so that I can correct mistakes or update information.

## Acceptance Criteria

1. **Given** I own a vehicle, **When** I visit its edit page and submit valid changes, **Then** the details are updated **And** I am redirected to the vehicles list with a `flash[:notice]` confirmation.
2. **Given** I submit with a required field cleared, **When** the form is submitted, **Then** I see a validation error and the form re-renders with `status: 422`.
3. **Given** another user's vehicle ID is used in the URL, **When** I attempt to access the edit page or submit an update, **Then** I am redirected to root with a `flash[:alert]` (ARC10 — RecordNotFound handling already in ApplicationController).

## Tasks / Subtasks

- [x] Task 1: Add `edit` and `update` actions to VehiclesController (AC: #1, #2, #3)
  - [x] Add `before_action :set_vehicle, only: [:edit, :update]` with `current_user.vehicles.find(params[:id])` — triggers RecordNotFound for wrong-user access.
  - [x] `edit` action: simply renders the `edit` template with `@vehicle`.
  - [x] `update` action: call `@vehicle.update(vehicle_params)`; on success `redirect_to vehicles_path, notice: "Vehicle updated successfully."`; on failure `render :edit, status: :unprocessable_entity`.
  - [x] `vehicle_params` already defined — no changes needed, all editable fields already permitted.

- [x] Task 2: Create `app/views/vehicles/edit.html.erb` (AC: #1, #2)
  - [x] Page heading: "Edit Vehicle".
  - [x] Render the existing `_form` partial: `<%= render 'form', vehicle: @vehicle %>`.
  - [x] The existing `_form` partial is already compatible with edit (uses `form_with(model: vehicle)` which auto-routes to PATCH for persisted records — no changes to `_form` needed).

- [x] Task 3: Surface "Edit" link from vehicle card and index (AC: #1)
  - [x] Add an "Edit" button to `app/views/shared/_vehicle_card.html.erb` alongside the existing "View" link: `<%= link_to "Edit", edit_vehicle_path(vehicle), class: "btn btn-sm btn-outline-secondary" %>`.

- [x] Task 4: Add request specs for edit/update actions (AC: #1–#3)
  - [x] Add to `spec/requests/vehicles_spec.rb` (do NOT create a new file):
    - `GET /vehicles/:id/edit` — unauthenticated → redirects to sign-in.
    - `GET /vehicles/:id/edit` — authenticated, own vehicle → 200.
    - `GET /vehicles/:id/edit` — authenticated, other user's vehicle → redirect to root.
    - `PATCH /vehicles/:id` — valid params → redirects to `/vehicles`, flash[:notice] set.
    - `PATCH /vehicles/:id` — invalid params (missing make) → 422, re-renders edit form.
    - `PATCH /vehicles/:id` — other user's vehicle → redirect to root.

### Review Findings

- [x] [Review][Patch] Unauthorized PATCH spec does not assert no mutation [spec/requests/vehicles_spec.rb:157-160]
- [x] [Review][Patch] Missing not-found ID coverage for edit/update request specs [spec/requests/vehicles_spec.rb:103-163]

## Dev Notes

### Architecture & Critical Constraints

- **Ownership scoping is MANDATORY** — use `current_user.vehicles.find(params[:id])` for every `set_vehicle`. Never bare `Vehicle.find`. [Source: architecture.md#Authentication & Security, #Process Patterns]
- **RecordNotFound already rescued** — `ApplicationController` has `rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found` which redirects to `root_path` with `flash[:alert]`. This automatically satisfies AC #3 for both `edit` and `update`. Do NOT add custom rescue logic.
- **Global auth** — `before_action :authenticate_user!` is in `ApplicationController`. No additional auth in VehiclesController needed.
- **Flash keys** — `flash[:notice]` for success, `flash[:alert]` for errors. NEVER `:success`, `:info`, `:error`, `:danger`. [Source: architecture.md#Format Patterns]
- **Turbo-compatible rendering** — always `render :edit, status: :unprocessable_entity` on update failure. [Source: architecture.md#Process Patterns]
- **Redirect after success** → `vehicles_path` (the index). Do NOT redirect to `vehicle_path(@vehicle)` — `VehiclesController#show` is not implemented in this epic (deferred to Epic 5 for per-vehicle detail view + due-soon display).

### VehiclesController — Canonical Edit/Update Pattern

```ruby
class VehiclesController < ApplicationController
  before_action :set_vehicle, only: [:edit, :update]

  # ... existing index, new, create ...

  def edit
  end

  def update
    if @vehicle.update(vehicle_params)
      redirect_to vehicles_path, notice: "Vehicle updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_vehicle
    @vehicle = current_user.vehicles.find(params[:id])
  end

  def vehicle_params
    params.require(:vehicle).permit(:make, :model, :year, :current_mileage)
  end
end
```

### `edit.html.erb` — Canonical Pattern

```erb
<div class="container py-4">
  <h1 class="mb-4">Edit Vehicle</h1>
  <%= render 'form', vehicle: @vehicle %>
</div>
```

The `_form` partial uses `form_with(model: vehicle)` — Rails auto-selects POST vs PATCH based on `vehicle.persisted?`. No changes to the partial are needed.

### `_vehicle_card` Edit Link Addition

Add after the existing "View" link:

```erb
<%= link_to "Edit", edit_vehicle_path(vehicle), class: "btn btn-sm btn-outline-secondary" %>
```

Note: the "View" link (`vehicle_path`) will still produce a 404/routing issue since `VehiclesController#show` is not yet implemented (deferred to Epic 5). The "View" link is already noted as deferred in story 2.1 review findings — do NOT implement or remove it in this story.

### Request Spec Pattern (add to existing `spec/requests/vehicles_spec.rb`)

```ruby
describe "GET /vehicles/:id/edit" do
  context "when unauthenticated" do
    it "redirects to sign-in" do
      vehicle = create(:vehicle)
      get edit_vehicle_path(vehicle)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "when authenticated" do
    let(:user) { create(:user) }
    let(:vehicle) { create(:vehicle, user: user) }

    before { sign_in user }

    it "returns 200 for own vehicle" do
      get edit_vehicle_path(vehicle)
      expect(response).to have_http_status(:ok)
    end

    it "redirects to root for another user's vehicle" do
      other_vehicle = create(:vehicle)
      get edit_vehicle_path(other_vehicle)
      expect(response).to redirect_to(root_path)
    end
  end
end

describe "PATCH /vehicles/:id" do
  let(:user) { create(:user) }
  let(:vehicle) { create(:vehicle, user: user) }

  before { sign_in user }

  it "updates vehicle and redirects with notice" do
    patch vehicle_path(vehicle), params: { vehicle: { make: "Honda" } }
    expect(response).to redirect_to(vehicles_path)
    expect(vehicle.reload.make).to eq("Honda")
  end

  it "re-renders edit with 422 on invalid params" do
    patch vehicle_path(vehicle), params: { vehicle: { make: "" } }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "redirects to root for another user's vehicle" do
    other_vehicle = create(:vehicle)
    patch vehicle_path(other_vehicle), params: { vehicle: { make: "Honda" } }
    expect(response).to redirect_to(root_path)
  end
end
```

### Schema (no changes needed)

```
vehicles: id, user_id (FK → users.id), make (string), model (string), year (integer), current_mileage (integer), created_at, updated_at
```

No new migrations required for this story.

### Routes (no changes needed)

Full nested routes were added in Story 2.1 — `resources :vehicles` already covers `edit` and `update` via `PATCH /vehicles/:id`. Verify with `rails routes | grep vehicle`.

### Project Structure Notes

Files to create/modify:
- `app/controllers/vehicles_controller.rb` — add `set_vehicle` before_action, `edit`, `update` actions
- `app/views/vehicles/edit.html.erb` — new view
- `app/views/shared/_vehicle_card.html.erb` — add "Edit" link
- `spec/requests/vehicles_spec.rb` — append edit/update specs (do NOT create new spec file)

Files NOT to touch:
- `config/routes.rb` — already correct from Story 2.1
- `db/migrate/` — no schema changes
- `app/views/vehicles/_form.html.erb` — already compatible, no changes needed
- Any other existing spec files

### Previous Story Intelligence (2.1)

- `spec/support/devise.rb` configured — use `sign_in user` in request specs.
- `spec/factories/vehicles.rb` exists with `association :user` — use `create(:vehicle, user: user)` for owned vehicles and `create(:vehicle)` for other-user vehicles.
- Bootstrap-styled forms with labeled fields and `devise/shared/error_messages` partial for validation error display — already in `_form`.
- `before_action :set_vehicle` + `current_user.vehicles.find` is the established pattern for authorized scoping.

### References

- Story requirements: `_bmad-output/planning-artifacts/epics.md#Story 2.2`
- Ownership scoping: `_bmad-output/planning-artifacts/architecture.md#Process Patterns`
- Auth/security: `_bmad-output/planning-artifacts/architecture.md#Authentication & Security`
- RecordNotFound rescue: `app/controllers/application_controller.rb`
- Flash conventions: `_bmad-output/planning-artifacts/architecture.md#Format Patterns`
- Prior story context: `_bmad-output/implementation-artifacts/2-1-add-list-vehicles.md`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4.6

### Debug Log References

### Completion Notes List

- Story 2.2 implemented. Added `edit` and `update` actions to `VehiclesController` with `before_action :set_vehicle` scoped via `current_user.vehicles.find` — wrong-user access automatically triggers `RecordNotFound` → root redirect via existing `ApplicationController` rescue. Created `app/views/vehicles/edit.html.erb` reusing the existing `_form` partial (no partial changes needed). Added "Edit" button to `_vehicle_card`. Appended 7 request specs to existing `vehicles_spec.rb` covering all ACs. Full suite: 59 examples, 0 failures.

### File List

- `app/controllers/vehicles_controller.rb` (modified — added `set_vehicle` before_action, `edit`, `update` actions)
- `app/views/vehicles/edit.html.erb` (created)
- `app/views/shared/_vehicle_card.html.erb` (modified — added "Edit" link)
- `spec/requests/vehicles_spec.rb` (modified — appended edit/update specs)

## Change Log

- 2026-04-27: Story 2.2 created — Edit Vehicle Details context prepared for development.
- 2026-04-27: Story 2.2 implemented — VehiclesController edit/update, edit view, vehicle card Edit link, 7 new request specs. 59 examples, 0 failures.
