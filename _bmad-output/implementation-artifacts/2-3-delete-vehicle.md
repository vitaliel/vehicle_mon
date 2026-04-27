# Story 2.3: Delete Vehicle

Status: review

## Story

As an authenticated user,
I want to delete a vehicle and all its associated data,
so that I can remove a car I no longer own.

## Acceptance Criteria

1. **Given** I own a vehicle (with or without associated service log entries and thresholds), **When** I delete it, **Then** the vehicle and all its associated records are permanently deleted (cascade) **And** I am redirected to the vehicles list with a `flash[:notice]` confirmation.
2. **Given** another user's vehicle ID is used in a delete request, **When** the request is processed, **Then** I am redirected to root with a `flash[:alert]` (ARC10 — RecordNotFound rescue in ApplicationController).

## Tasks / Subtasks

- [x] Task 1: Add `destroy` action to VehiclesController (AC: #1, #2)
  - [x] Extend `before_action :set_vehicle` to include `:destroy`.
  - [x] Add `destroy` action: call `@vehicle.destroy`, then `redirect_to vehicles_path, notice: "Vehicle deleted successfully."`.
  - [x] Do NOT add custom authorization or rescue logic — ownership scoping via `current_user.vehicles.find` triggers `RecordNotFound` for wrong-user access, already rescued by `ApplicationController`.

- [x] Task 2: Add "Delete" button to `app/views/shared/_vehicle_card.html.erb` (AC: #1)
  - [x] Add delete link after the "Edit" button using Turbo method override: `link_to "Delete", vehicle_path(vehicle), data: { turbo_method: :delete, turbo_confirm: "Are you sure you want to delete this vehicle?" }, class: "btn btn-sm btn-outline-danger"`.

- [x] Task 3: Add request specs for destroy action (AC: #1–#2)
  - [x] Add to `spec/requests/vehicles_spec.rb` (do NOT create a new file):
    - `DELETE /vehicles/:id` — unauthenticated → redirects to sign-in.
    - `DELETE /vehicles/:id` — authenticated, own vehicle → redirects to `/vehicles`, flash[:notice] set, vehicle count decreases by 1.
    - `DELETE /vehicles/:id` — authenticated, other user's vehicle → redirects to root, vehicle NOT deleted.

## Dev Notes

### Architecture & Critical Constraints

- **Ownership scoping is MANDATORY** — always use `current_user.vehicles.find(params[:id])` in `set_vehicle`. Never use bare `Vehicle.find`. [Source: architecture.md#Authentication & Security, #Process Patterns]
- **RecordNotFound already rescued** — `ApplicationController` has `rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found` → redirects to `root_path` with `flash[:alert]`. This satisfies AC #2 automatically. Do NOT add custom rescue logic.
- **Cascade deletes are already wired** — `Vehicle` model has `has_many :service_log_entries, dependent: :destroy` and `has_many :reminder_thresholds, dependent: :destroy`. Calling `@vehicle.destroy` is sufficient — no migration or manual cleanup needed.
- **Flash keys** — `flash[:notice]` for success, `flash[:alert]` for errors. NEVER `:success`, `:info`, `:error`, `:danger`. [Source: architecture.md#Format Patterns]
- **Global auth** — `before_action :authenticate_user!` is in `ApplicationController`. No additional auth needed.
- **Redirect after success** → `vehicles_path` (the index). No `show` action exists in this epic.

### VehiclesController — Canonical Destroy Pattern

```ruby
class VehiclesController < ApplicationController
  before_action :set_vehicle, only: [:edit, :update, :destroy]  # ADD :destroy here

  # ... existing index, new, create, edit, update ...

  def destroy
    @vehicle.destroy
    redirect_to vehicles_path, notice: "Vehicle deleted successfully."
  end

  private

  def set_vehicle
    @vehicle = current_user.vehicles.find(params[:id])
  end
end
```

### `_vehicle_card` Delete Link Addition

Add after the existing "Edit" button:

```erb
<%= link_to "Delete", vehicle_path(vehicle),
      data: { turbo_method: :delete, turbo_confirm: "Are you sure you want to delete this vehicle?" },
      class: "btn btn-sm btn-outline-danger" %>
```

**Note on Turbo:** `data: { turbo_method: :delete }` is the Rails 7+/Turbo way to issue a non-GET request from a link. It does NOT require any custom JavaScript — Turbo handles it automatically. Do NOT use the old `method: :delete` (Rails UJS) approach.

### Routes (no changes needed)

`resources :vehicles` added in Story 2.1 already generates `DELETE /vehicles/:id → vehicles#destroy`. Verify with `rails routes | grep "DELETE.*vehicles"`.

### Schema (no changes needed)

No new migrations. Cascade is handled at the Rails model level via `dependent: :destroy`, not at the DB constraint level. The Vehicle model already declares:

```ruby
has_many :service_log_entries, dependent: :destroy
has_many :reminder_thresholds, dependent: :destroy
```

### Request Spec Pattern (add to existing `spec/requests/vehicles_spec.rb`)

```ruby
describe "DELETE /vehicles/:id" do
  context "when unauthenticated" do
    it "redirects to sign-in" do
      vehicle = create(:vehicle)
      delete vehicle_path(vehicle)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "when authenticated" do
    let(:user) { create(:user) }
    let(:vehicle) { create(:vehicle, user: user) }

    before { sign_in user }

    it "deletes own vehicle and redirects with notice" do
      vehicle  # ensure record exists before count assertion
      expect {
        delete vehicle_path(vehicle)
      }.to change(Vehicle, :count).by(-1)
      expect(response).to redirect_to(vehicles_path)
      follow_redirect!
      expect(response.body).to include("deleted successfully")
    end

    it "redirects to root for another user's vehicle without deleting it" do
      other_vehicle = create(:vehicle)
      expect {
        delete vehicle_path(other_vehicle)
      }.not_to change(Vehicle, :count)
      expect(response).to redirect_to(root_path)
    end
  end
end
```

### Project Structure Notes

Files to modify:
- `app/controllers/vehicles_controller.rb` — extend `before_action :set_vehicle` to include `:destroy`; add `destroy` action
- `app/views/shared/_vehicle_card.html.erb` — add "Delete" link

Files NOT to touch:
- `config/routes.rb` — already has `resources :vehicles` from Story 2.1
- `db/migrate/` — no schema changes
- `app/models/vehicle.rb` — cascade already defined
- Any other view files

Do NOT create a new spec file — append specs to the existing `spec/requests/vehicles_spec.rb`.

### Previous Story Intelligence (2.2)

- `spec/support/devise.rb` configured — use `sign_in user` in request specs.
- `spec/factories/vehicles.rb` exists with `association :user` — use `create(:vehicle, user: user)` for owned vehicles and `create(:vehicle)` for other-user vehicles.
- `before_action :set_vehicle` + `current_user.vehicles.find` is the established ownership scoping pattern — just extend it to `:destroy`.
- Bootstrap buttons use `btn btn-sm btn-outline-*` class convention in the vehicle card.
- The "View" link (`vehicle_path`) will still produce a 404/routing issue since `VehiclesController#show` is deferred to Epic 5 — do NOT implement or remove it.

### References

- Story requirements: `_bmad-output/planning-artifacts/epics.md#Story 2.3`
- Ownership scoping: `_bmad-output/planning-artifacts/architecture.md#Process Patterns`
- Auth/security: `_bmad-output/planning-artifacts/architecture.md#Authentication & Security`
- RecordNotFound rescue: `app/controllers/application_controller.rb`
- Flash conventions: `_bmad-output/planning-artifacts/architecture.md#Format Patterns`
- Cascade setup: `app/models/vehicle.rb`
- Prior story context: `_bmad-output/implementation-artifacts/2-2-edit-vehicle-details.md`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4.6

### Debug Log References

### Completion Notes List

- Story 2.3 implemented. Extended `before_action :set_vehicle` in `VehiclesController` to include `:destroy`. Added `destroy` action calling `@vehicle.destroy` followed by `redirect_to vehicles_path, notice: "Vehicle deleted successfully."`. Wrong-user access automatically triggers `RecordNotFound` → root redirect via existing `ApplicationController` rescue — no custom authorization needed. Added "Delete" button to `_vehicle_card` using `data: { turbo_method: :delete, turbo_confirm: ... }` Turbo pattern. Appended 3 request specs to existing `vehicles_spec.rb` covering all ACs. Full suite: 64 examples, 0 failures.

### File List

- `app/controllers/vehicles_controller.rb` (modified — extended `before_action :set_vehicle` to include `:destroy`; added `destroy` action)
- `app/views/shared/_vehicle_card.html.erb` (modified — added "Delete" link with Turbo method override)
- `spec/requests/vehicles_spec.rb` (modified — appended 3 DELETE specs)

## Change Log

- 2026-04-27: Story 2.3 created — Delete Vehicle context prepared for development.
- 2026-04-27: Story 2.3 implemented — VehiclesController destroy action, vehicle card Delete button, 3 new request specs. 64 examples, 0 failures.
