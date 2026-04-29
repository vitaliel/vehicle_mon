# Story 3.5: Delete Service Log Entry

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an authenticated user,
I want to delete a service log entry,
so that I can remove incorrectly logged records.

## Acceptance Criteria

1. **Given** I own a service log entry, **When** I delete it, **Then** the entry is permanently removed from the database and I am redirected to the service history index for that vehicle with a `flash[:notice]` confirmation.

2. **Given** another user's entry ID is used in a DELETE request, **When** the request is processed, **Then** I am redirected to root with a `flash[:alert]`.

## Tasks / Subtasks

- [x] Task 1: Add `:destroy` to routes (AC: #1, #2)
  - [x] In `config/routes.rb`, change `only: [:index, :new, :create, :edit, :update]` to include `:destroy`

- [x] Task 2: Add `destroy` action and `set_entry` before_action extension to `ServiceLogEntriesController` (AC: #1, #2)
  - [x] Extend `before_action :set_entry, only: [:edit, :update]` to include `:destroy`
  - [x] Add `destroy` action: call `@entry.destroy`, then `redirect_to vehicle_service_log_entries_path(@vehicle), notice: "Service entry deleted successfully."`

- [x] Task 3: Add "Delete" button in the service history index table (AC: #1)
  - [x] In `app/views/service_log_entries/index.html.erb`, add a `button_to "Delete"` in the Actions `<td>` alongside the existing "Edit" link, using `method: :delete` and a `data-turbo-confirm` prompt

- [x] Task 4: Write request specs (AC: #1, #2)
  - [x] `DELETE /vehicles/:vehicle_id/service_log_entries/:id` unauthenticated — redirects to sign-in
  - [x] `DELETE` authenticated as owner — destroys entry, redirects to index with `flash[:notice]`
  - [x] `DELETE` with another user's entry — redirects to root with `flash[:alert]`

### Review Findings

- [x] [Review][Patch] Destroy action reports success even when deletion fails [app/controllers/service_log_entries_controller.rb:37]

## Dev Notes

### Controller Changes (MOST IMPORTANT)

The current `ServiceLogEntriesController` has `index`, `new`, `create`, `edit`, `update` with a `set_entry` before_action for `edit` and `update`. Extend it minimally:

```ruby
before_action :set_entry, only: [ :edit, :update, :destroy ]   # add :destroy

def destroy
  @entry.destroy
  redirect_to vehicle_service_log_entries_path(@vehicle), notice: "Service entry deleted successfully."
end
```

**Authorization is automatic** — `@vehicle.service_log_entries.find(params[:id])` raises `ActiveRecord::RecordNotFound` when the entry doesn't belong to the vehicle owned by `current_user`. `ApplicationController#handle_not_found` redirects to root with `alert: "Record not found."`. Do NOT add a separate rescue block.

### Routes Change (Required)

```ruby
# config/routes.rb — current (must change):
resources :service_log_entries, only: [ :index, :new, :create, :edit, :update ]

# Change to:
resources :service_log_entries, only: [ :index, :new, :create, :edit, :update, :destroy ]
```

This generates `vehicle_service_log_entry_path(@vehicle, @entry)` with `DELETE` verb.

### View: Index Table — Add Delete Button

The Actions `<td>` currently has only the Edit link. Add the Delete button alongside it:

```erb
<td>
  <%= link_to "Edit", edit_vehicle_service_log_entry_path(@vehicle, entry),
        class: "btn btn-sm btn-outline-secondary" %>
  <%= button_to "Delete", vehicle_service_log_entry_path(@vehicle, entry),
        method: :delete,
        data: { turbo_confirm: "Delete this service entry?" },
        class: "btn btn-sm btn-outline-danger ms-1",
        form: { style: "display:inline" } %>
</td>
```

**Use `button_to` not `link_to` for destructive actions** — it emits a `<form>` with `method: :delete`, which is the Rails/Turbo convention. Using `link_to` with `method: :delete` works only with Turbo Drive; `button_to` is safer and more accessible.

### Flash Keys (Must Follow)

- Success redirect: `flash[:notice]` only — use `"Service entry deleted successfully."`
- Auth/not-found redirect: `flash[:alert]` only (set automatically by `handle_not_found`)

Never use `flash[:success]`, `flash[:error]`, `flash[:info]`, or `flash[:danger]`.
[Source: _bmad-output/planning-artifacts/architecture.md#Format Patterns]

### Request Specs Pattern

Add within the existing `spec/requests/service_log_entries_spec.rb` after the PATCH describe block:

```ruby
describe "DELETE /vehicles/:vehicle_id/service_log_entries/:id" do
  let(:entry) { create(:service_log_entry, vehicle: vehicle, service_type: service_type) }

  context "when unauthenticated" do
    it "redirects to sign-in" do
      delete vehicle_service_log_entry_path(vehicle, entry)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "when authenticated as owner" do
    before { sign_in user }

    it "destroys the entry and redirects to index with flash[:notice]" do
      entry  # ensure created before delete
      expect {
        delete vehicle_service_log_entry_path(vehicle, entry)
      }.to change(ServiceLogEntry, :count).by(-1)
      expect(response).to redirect_to(vehicle_service_log_entries_path(vehicle))
      expect(flash[:notice]).to eq("Service entry deleted successfully.")
    end
  end

  context "when accessing another user's entry (cross-user)" do
    before { sign_in user }

    it "redirects to root with flash[:alert]" do
      other_vehicle = create(:vehicle, user: other_user)
      other_entry = create(:service_log_entry, vehicle: other_vehicle, service_type: service_type)
      delete vehicle_service_log_entry_path(other_vehicle, other_entry)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end
end
```

### Testing Standards

- Run `bundle exec rspec` before and after changes — must stay at **0 failures** (currently **114 specs pass**, 2 pre-existing pending stubs).
- Add specs to the existing `spec/requests/service_log_entries_spec.rb` — do NOT create a new file.
- Use `sign_in user` (Devise test helpers, configured in `spec/rails_helper.rb`).
- Materialize `let(:entry)` before calling `delete` when using `change` matcher (call `entry` once before the expect block).

### Project Structure Notes

**Files to MODIFY:**
- `config/routes.rb` — add `:destroy` to `service_log_entries` only list
- `app/controllers/service_log_entries_controller.rb` — extend `:set_entry` before_action, add `destroy` action
- `app/views/service_log_entries/index.html.erb` — add Delete button in Actions column
- `spec/requests/service_log_entries_spec.rb` — add DELETE describe block

**Files to NOT touch:**
- `app/views/service_log_entries/_form.html.erb` — unrelated
- `app/models/service_log_entry.rb` — no model changes needed
- `app/views/service_log_entries/new.html.erb` / `edit.html.erb` — unrelated
- Any Epic 4 or Epic 5 files — out of scope

### Previous Story Learnings (Story 3.4)

- **114 specs pass** (0 failures, 2 pre-existing pending stubs) — run `bundle exec rspec` before starting to confirm baseline.
- Routes had an explicit `only:` restriction — **check and update** `config/routes.rb`; the architecture doc implies full CRUD but the routes file uses explicit `only:` lists.
- Cross-user protection is **free** via double-scoped ownership: `current_user.vehicles.find` + `@vehicle.service_log_entries.find` — both wrong `vehicle_id` and wrong `entry_id` are automatically blocked by `handle_not_found`.
- Flash key: always `flash[:notice]` (success) and `flash[:alert]` (error/redirect).
- `sign_in user` via Devise helpers — no session manipulation needed.
- Turbo is active — use `button_to` with `method: :delete` for destructive actions (not `link_to` with `data-method`).

### References

- Story ACs: `_bmad-output/planning-artifacts/epics.md#Story 3.5: Delete Service Log Entry`
- Epic context: `_bmad-output/planning-artifacts/epics.md#Epic 3: Service History Logging`
- Architecture flash keys: `_bmad-output/planning-artifacts/architecture.md#Format Patterns`
- Auth/ownership pattern: `_bmad-output/planning-artifacts/architecture.md#Authorization`
- Existing controller: `app/controllers/service_log_entries_controller.rb`
- Existing index view: `app/views/service_log_entries/index.html.erb`
- Existing specs: `spec/requests/service_log_entries_spec.rb`
- Routes: `config/routes.rb`
- Auth enforcement: `app/controllers/application_controller.rb`
- Delete pattern reference (vehicle): `app/controllers/vehicles_controller.rb`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4.6

### Debug Log References

- No unexpected issues. Routes had explicit `only:` list as anticipated — added `:destroy` as documented.

### Completion Notes List

- Added `:destroy` to `service_log_entries` route `only:` list in `config/routes.rb`.
- Extended `before_action :set_entry` to include `:destroy` in `ServiceLogEntriesController`; cross-user protection is automatic via double-scoped ownership chain.
- Added `destroy` action: `@entry.destroy` + redirect to index with `flash[:notice]: "Service entry deleted successfully."`.
- Added `button_to "Delete"` with `method: :delete` and `data: { turbo_confirm: ... }` in the Actions cell of `index.html.erb`, alongside existing Edit link.
- Added 3 new request specs (unauthenticated redirect, owner delete with count assertion, cross-user redirect) to existing `spec/requests/service_log_entries_spec.rb`.
- **117 specs pass, 0 failures**, 2 pre-existing pending stubs unchanged.

### File List

- `config/routes.rb` (modified — added :destroy to service_log_entries)
- `app/controllers/service_log_entries_controller.rb` (modified — extended set_entry, added destroy action)
- `app/views/service_log_entries/index.html.erb` (modified — added Delete button in Actions column)
- `spec/requests/service_log_entries_spec.rb` (modified — added DELETE describe block with 3 specs)
- `_bmad-output/implementation-artifacts/3-5-delete-service-log-entry.md` (story updated)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (updated)
