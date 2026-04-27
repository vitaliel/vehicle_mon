# Story 2.1: Add & List Vehicles

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an authenticated user,
I want to add a vehicle with make, model, year, and current mileage, and view my list of vehicles,
so that I can start tracking maintenance for my cars.

## Acceptance Criteria

1. **Given** I am signed in, **When** I visit `/vehicles`, **Then** I see a list of all my registered vehicles rendered via the `_vehicle_card` partial, or an empty-state message prompting me to add my first vehicle.
2. **Given** I fill in make, model, year, and current mileage and submit, **When** the vehicle is saved, **Then** it appears in my vehicle list, **And** a `flash[:notice]` confirmation is shown.
3. **Given** the vehicle is saved, **Then** it is scoped to my account only — other users cannot see it (NFR5/ARC5).
4. **Given** I submit with a required field missing (e.g., no make), **When** the form is submitted, **Then** I see a validation error and the form re-renders with `status: 422`.
5. **Given** I am on mobile (375px viewport), **When** I view or submit the vehicle form, **Then** all inputs and touch targets are usable (NFR14).

## Tasks / Subtasks

- [ ] Task 1: Create Vehicle model and migration (AC: #2, #3)
  - [ ] Generate migration: `vehicles(user_id:references, make:string, model:string, year:integer, current_mileage:integer)`.
  - [ ] Add `belongs_to :user` and `has_many :service_log_entries, dependent: :destroy` and `has_many :reminder_thresholds, dependent: :destroy` to `Vehicle`.
  - [ ] Add model validations: `validates :make, :model, presence: true`; `validates :year, numericality: { only_integer: true, greater_than: 1885, less_than_or_equal_to: Date.current.year + 1 }`; `validates :current_mileage, numericality: { only_integer: true, greater_than_or_equal_to: 0 }`.
  - [ ] Add `has_many :vehicles, dependent: :destroy` to `User` model.

- [ ] Task 2: Create VehiclesController with index, new, create actions (AC: #1, #2, #3, #4)
  - [ ] Create `app/controllers/vehicles_controller.rb` with `index`, `new`, `create` actions.
  - [ ] Scope all queries through `current_user.vehicles` — never `Vehicle.find`.
  - [ ] `index`: `@vehicles = current_user.vehicles.order(created_at: :desc)`.
  - [ ] `create`: on success redirect to `vehicles_path` with `flash[:notice]`; on failure `render :new, status: :unprocessable_entity`.

- [ ] Task 3: Add vehicle routes (AC: #1, #2)
  - [ ] Replace `root "pages#index"` with `root "pages#index"` (leave root for now — dashboard is Epic 5).
  - [ ] Add full nested routes per architecture spec:
    ```ruby
    resources :vehicles do
      resources :service_log_entries
      resources :reminder_thresholds
      member do
        patch :update_mileage
      end
    end
    ```
  - [ ] Remove the placeholder `get "pages/index"` route after confirming root still works.

- [ ] Task 4: Create views (AC: #1, #2, #4, #5)
  - [ ] Create `app/views/vehicles/index.html.erb`: page heading "My Vehicles", "Add Vehicle" button (`new_vehicle_path`), list rendering `_vehicle_card` partial for each vehicle, empty-state div if `@vehicles.empty?`.
  - [ ] Create `app/views/vehicles/new.html.erb`: page heading "Add Vehicle", render `_form` partial.
  - [ ] Create `app/views/vehicles/_form.html.erb`: Bootstrap form with labeled fields for make (text), model (text), year (number), current mileage (number); submit button; render `devise/shared/error_messages` partial for validation errors.
  - [ ] Create/update `app/views/shared/_vehicle_card.html.erb`: Bootstrap card showing make, model, year, current mileage (formatted with `number_with_delimiter`). Include a "View" link to `vehicle_path(vehicle)` (show page not required for this story but link can point there for future use).
  - [ ] Add "My Vehicles" nav link to `app/views/layouts/application.html.erb` for signed-in users.

- [ ] Task 5: Create Vehicle factory and specs (AC: #1–#5)
  - [ ] Create `spec/factories/vehicles.rb` with a valid vehicle associated to a user.
  - [ ] Create `spec/models/vehicle_spec.rb`: test all presence and numericality validations using Shoulda Matchers; test `belongs_to :user`.
  - [ ] Create `spec/requests/vehicles_spec.rb`:
    - GET `/vehicles` — unauthenticated → redirects to sign-in.
    - GET `/vehicles` — authenticated, no vehicles → 200, empty state rendered.
    - GET `/vehicles` — authenticated, with vehicles → 200, vehicle make/model visible.
    - GET `/vehicles` — authenticated → only shows current user's vehicles (cross-user scoping).
    - GET `/vehicles/new` — authenticated → 200.
    - POST `/vehicles` with valid params → redirects to `/vehicles`, flash[:notice] set.
    - POST `/vehicles` with invalid params (missing make) → 422, re-renders new form.

## Dev Notes

### Architecture and Constraints

- **Ownership scoping is mandatory** — every query MUST go through `current_user.vehicles`. Never use `Vehicle.find(params[:id])` directly. [Source: architecture.md#Authentication & Security]
- **RecordNotFound already rescued** — `ApplicationController` already has `rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found` which redirects to `root_path` with `flash[:alert]`. Do not reimplement.  [Source: app/controllers/application_controller.rb]
- **Global auth enforcement already active** — `before_action :authenticate_user!` is already in `ApplicationController`. No additional auth setup needed in `VehiclesController`.
- **Flash keys** — use `flash[:notice]` for success, `flash[:alert]` for errors. Never `:success`, `:info`, `:error`, `:danger`. [Source: architecture.md#Format Patterns]
- **Validation failure rendering** — always `render :new, status: :unprocessable_entity` on create failure for Turbo compatibility. [Source: architecture.md#Process Patterns]
- **Mileage display format** — use `number_with_delimiter` helper, e.g. `"92,400 km"`. [Source: architecture.md#Format Patterns]
- **Bootstrap 5.3.8 CDN** — already loaded in application layout. No Node/Yarn build step needed. Use Bootstrap grid and form classes throughout. [Source: app/views/layouts/application.html.erb]

### Schema

```
vehicles: id, user_id (FK → users.id), make (string), model (string), year (integer), current_mileage (integer), created_at, updated_at
```

- `user_id` index is added automatically by `references` in migration.
- `current_mileage` stores whole numbers only (no decimals).
- `year` valid range: > 1885 and ≤ current year + 1.

### VehiclesController — Canonical Pattern

```ruby
class VehiclesController < ApplicationController
  def index
    @vehicles = current_user.vehicles.order(created_at: :desc)
  end

  def new
    @vehicle = current_user.vehicles.build
  end

  def create
    @vehicle = current_user.vehicles.build(vehicle_params)
    if @vehicle.save
      redirect_to vehicles_path, notice: "Vehicle added successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def vehicle_params
    params.require(:vehicle).permit(:make, :model, :year, :current_mileage)
  end
end
```

### Routes — Full Structure (per architecture spec)

Even though only index/new/create are implemented in this story, add the full nested route block now so future stories don't require route conflicts:

```ruby
resources :vehicles do
  resources :service_log_entries
  resources :reminder_thresholds
  member do
    patch :update_mileage
  end
end
```

Remove the placeholder `get "pages/index"` line. Keep `root "pages#index"` — dashboard is Epic 5.

### `_vehicle_card` Partial

Architecture specifies `app/views/shared/_vehicle_card.html.erb` is used on **both dashboard and vehicles#index**. This partial must be created in this story. Suggested content:

```erb
<div class="card mb-3">
  <div class="card-body">
    <h5 class="card-title"><%= vehicle.year %> <%= vehicle.make %> <%= vehicle.model %></h5>
    <p class="card-text text-muted"><%= number_with_delimiter(vehicle.current_mileage) %> km</p>
    <%= link_to "View", vehicle_path(vehicle), class: "btn btn-sm btn-outline-primary" %>
  </div>
</div>
```

Render it as: `<%= render 'shared/vehicle_card', vehicle: vehicle %>` (explicit local variable).

### Navigation Update

Add a "My Vehicles" link to the existing navbar in `app/views/layouts/application.html.erb` for signed-in users, alongside the existing Account Settings and Sign out links.

### Previous Story Intelligence (1.4)

- Story 1.4 established the pattern of using Bootstrap-styled forms with labeled fields and the `devise/shared/error_messages` partial for error display. Follow the same form structure.
- `spec/support/devise.rb` is already configured; use `sign_in user` in request specs for authenticated scenarios.
- `spec/factories/users.rb` exists with `sequence(:email)` pattern; Vehicle factory should use `association :user` to link to a sequenced user.
- Request spec pattern established: use `sign_in user` before authenticated requests, assert on `response` status and rendered content.

### Project Structure Notes

Files to create/modify:
- `db/migrate/YYYYMMDD_create_vehicles.rb` (new migration)
- `app/models/vehicle.rb` (new model)
- `app/models/user.rb` (add `has_many :vehicles, dependent: :destroy`)
- `app/controllers/vehicles_controller.rb` (new controller)
- `app/views/vehicles/index.html.erb` (new)
- `app/views/vehicles/new.html.erb` (new)
- `app/views/vehicles/_form.html.erb` (new)
- `app/views/shared/_vehicle_card.html.erb` (create — was stubbed in story 1.1)
- `app/views/layouts/application.html.erb` (add My Vehicles nav link)
- `config/routes.rb` (add full nested vehicles resources, remove `get "pages/index"`)
- `spec/factories/vehicles.rb` (new factory)
- `spec/models/vehicle_spec.rb` (new model spec)
- `spec/requests/vehicles_spec.rb` (new request spec)
- `db/schema.rb` (auto-updated by migration)

### References

- Story requirements: `_bmad-output/planning-artifacts/epics.md#Story 2.1`
- Schema decisions: `_bmad-output/planning-artifacts/architecture.md#Data Architecture`
- Naming/routing patterns: `_bmad-output/planning-artifacts/architecture.md#Naming Patterns`, `#Structure Patterns`
- Process patterns: `_bmad-output/planning-artifacts/architecture.md#Process Patterns`
- Enforcement guidelines: `_bmad-output/planning-artifacts/architecture.md#Enforcement Guidelines`
- Prior story context: `_bmad-output/implementation-artifacts/1-4-account-details-management.md`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4.6

### Debug Log References

### Completion Notes List

- Story 2.1 context created. Epic 2 first story — Vehicle model, migration, VehiclesController (index/new/create), views, shared _vehicle_card partial, request + model specs.

### File List
