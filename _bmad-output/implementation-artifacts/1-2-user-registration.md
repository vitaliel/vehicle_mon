# Story 1.2: User Registration

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a visitor,
I want to register a new account with email and password,
so that I can access the Vehicle Service Tracker.

## Acceptance Criteria

1. **Given** I am not signed in, **When** I visit `/users/sign_up`, **Then** I see a registration form with email and password fields, **And** all form inputs have visible, associated labels (NFR11).
2. **Given** I submit valid email and password, **When** the form is submitted, **Then** my account is created and I am signed in, **And** I am redirected to the dashboard (root path), **And** a `flash[:notice]` confirmation message is shown.
3. **Given** I submit a duplicate email, **When** the form is submitted, **Then** I see a validation error message, **And** the form re-renders with `status: 422` (Turbo-compatible, ARC11).
4. **Given** I submit with a missing or invalid email, **When** the form is submitted, **Then** I see a specific validation error, **And** my password is never shown in logs or URLs (NFR9).

## Tasks / Subtasks

- [x] Task 1: Establish registration route and auth wiring (AC: #1, #2)
  - [x] Ensure Devise is installed and configured for `User` (`devise_for :users`, migration, model modules); if any part is missing, add it without replacing existing app structure.
  - [x] Keep dashboard/root route as the post-sign-up destination (configure Devise redirect hook only if default behavior does not land on `root_path`).
  - [x] Ensure unauthenticated users can access `/users/sign_up` while non-Devise pages remain compatible with upcoming global auth enforcement.
- [x] Task 2: Implement accessible registration UI and error behavior (AC: #1, #3, #4)
  - [x] Provide labeled email/password fields in sign-up form using Rails helpers (`f.label` + matching input ids) and keep Bootstrap-compatible markup.
  - [x] Ensure invalid submissions re-render the form with `status: :unprocessable_entity` (422) and visible validation feedback.
  - [x] Use existing flash partial conventions (`flash[:notice]` / `flash[:alert]` only).
- [x] Task 3: Add automated coverage for registration flow (AC: #1, #2, #3, #4)
  - [x] Add request specs for: GET `/users/sign_up`, successful sign-up redirect to root with notice, duplicate-email failure with 422, invalid email failure with 422.
  - [x] Add model spec coverage for `User` email validations if not already present.
  - [x] Verify existing suite remains green after registration behavior is added.

### Review Findings

- [x] [Review][Patch] Set explicit Devise mailer sender config using environment override [config/initializers/devise.rb:27]
- [x] [Review][Patch] Remove unrelated page-spec deletions from this story scope [spec/helpers/pages_helper_spec.rb:1]
- [x] [Review][Patch] Add explicit invalid-email request spec asserting 422 re-render behavior [spec/requests/registrations_spec.rb:1]
- [x] [Review][Patch] Remove sign-in tracking (`:trackable`) changes from registration story scope [app/models/user.rb:2]

## Dev Notes

- **Auth stack is mandated:** Devise 5.x with bcrypt-backed credentials; no custom authentication implementation. [Source: _bmad-output/planning-artifacts/architecture.md#Authentication & Security]
- **Routing boundary:** Devise routes (`/users/sign_up`, `/users/sign_in`, `/users/sign_out`) are public endpoints; broader app routes will be authenticated. [Source: _bmad-output/planning-artifacts/architecture.md#Authentication Boundary]
- **Turbo-compatible validation behavior:** on invalid form submit, render with `status: :unprocessable_entity`. [Source: _bmad-output/planning-artifacts/architecture.md#Process Patterns]
- **Flash key contract:** only `notice` and `alert` keys should be used. [Source: _bmad-output/planning-artifacts/architecture.md#Enforcement Guidelines]
- **Testing stack:** RSpec + FactoryBot + Shoulda Matchers; keep specs in standard `spec/` structure. [Source: _bmad-output/planning-artifacts/architecture.md#Testing Strategy]
- **From Story 1.1 implementation record:** shared flash partial exists and layout integration has been introduced; reuse that path instead of adding ad-hoc inline flash markup. [Source: _bmad-output/implementation-artifacts/1-1-rails-application-initialization.md#Completion Notes List]

### Project Structure Notes

- Expected touch points for this story:
  - `config/routes.rb` (Devise route wiring)
  - `app/models/user.rb` and Devise migration(s) if missing
  - `app/views/devise/registrations/new.html.erb` (or equivalent override if customization is needed)
  - `spec/requests/` and `spec/models/` for new coverage
- Keep changes scoped to registration only; sign-in/sign-out UX details belong to Story 1.3.

### References

- Epic requirements: `_bmad-output/planning-artifacts/epics.md` (Epic 1, Story 1.2)
- Functional requirements FR1/FR2 context: `_bmad-output/planning-artifacts/prd.md#User Account Management`
- Auth and implementation patterns: `_bmad-output/planning-artifacts/architecture.md#Authentication & Security`, `_bmad-output/planning-artifacts/architecture.md#Process Patterns`

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex (gpt-5.3-codex)

### Debug Log References

- `bcrypt` gem was commented out in Gemfile; uncommented and `bundle install` run.
- `rails generate devise User` created model, migration, factory, and model spec; also auto-inserted `devise_for :users` in routes.
- Devise initializer already had `config.responder.error_status = :unprocessable_content` — no custom controller needed for 422 behavior.
- `devise:views users` generated under `app/views/users/` (scoped path); moved shared partials to `app/views/devise/shared/` and removed `app/views/users/` since `scoped_views` is false.
- Bootstrap-compatible error messages partial created with `alert alert-danger` styling.
- 18 specs pass, 0 failures, no regressions.

### Completion Notes List

- Story context generated from Epic 1 / Story 1.2 with architecture and prior-story references.
- Ready for dev implementation.
- ✅ Task 1 complete: Devise User model created, `devise_for :users` added to routes, `db:migrate` run, bcrypt enabled.
- ✅ Task 2 complete: Custom `app/views/devise/registrations/new.html.erb` with labeled email/password fields (Bootstrap markup); 422 on invalid submit via Devise responder config.
- ✅ Task 3 complete: Request specs (GET sign_up, valid sign-up→root+notice, duplicate email→422, invalid email→422, missing email→422) and model specs (email validations, Devise modules). 18 examples, 0 failures.

### File List

- Gemfile (uncommented `bcrypt`)
- Gemfile.lock (updated)
- config/routes.rb (`devise_for :users` added by generator)
- app/models/user.rb (generated by `rails generate devise User`)
- db/migrate/20260427142021_devise_create_users.rb (generated Devise migration)
- db/schema.rb (updated after migration)
- app/views/devise/registrations/new.html.erb (custom Bootstrap registration form)
- app/views/devise/shared/_error_messages.html.erb (Bootstrap-styled validation errors)
- app/views/devise/shared/_links.html.erb (Devise navigation links)
- spec/models/user_spec.rb (email validation and Devise module specs)
- spec/factories/users.rb (valid user factory with email sequence)
- spec/requests/registrations_spec.rb (registration flow request specs)
- _bmad-output/implementation-artifacts/1-2-user-registration.md (this story)

## Change Log

- 2026-04-27: Implemented Story 1.2 — User Registration. Enabled bcrypt, generated Devise User model and migration, configured `devise_for :users` route, created Bootstrap-accessible registration view with labeled form fields, leveraged Devise responder config for 422 on validation failure. Added 18 specs (model validations + request flow). All tests pass, no regressions.
