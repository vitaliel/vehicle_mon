# Story 1.4: Account Details Management

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an authenticated user,
I want to view and update my account details (email and password),
so that I can keep my login credentials current.

## Acceptance Criteria

1. **Given** I am signed in, **When** I visit my account settings page (`/users/edit`), **Then** I see a form pre-filled with my current email.
2. **Given** I submit a valid email change, **When** the form is saved, **Then** my email is updated, **And** a `flash[:notice]` confirmation is shown.
3. **Given** I submit a password change with valid current password, **When** the form is saved, **Then** my password is updated and stored as a bcrypt hash (NFR6), **And** I remain signed in.
4. **Given** I submit a password change with an incorrect current password, **When** the form is submitted, **Then** I see a validation error and the change is rejected.

## Tasks / Subtasks

- [ ] Task 1: Add account settings access and edit UI (AC: #1)
  - [ ] Add an authenticated navigation link to account settings using `edit_user_registration_path`.
  - [ ] Create `app/views/devise/registrations/edit.html.erb` with Bootstrap layout matching existing Devise pages.
  - [ ] Ensure form includes labeled fields for email, current password, new password, and password confirmation (NFR11).
  - [ ] Keep Devise shared links and error rendering pattern (`devise/shared/error_messages`) for consistency.

- [ ] Task 2: Implement account update behavior through Devise defaults (AC: #2, #3, #4)
  - [ ] Use Devise `RegistrationsController#update` default flow (no custom controller override) for account edits.
  - [ ] Verify valid email update persists and success notice appears.
  - [ ] Verify valid password update requires correct current password and preserves signed-in session.
  - [ ] Verify incorrect current password rejects changes and re-renders with validation errors (`status: :unprocessable_entity`).

- [ ] Task 3: Add request coverage for account details flow (AC: #1, #2, #3, #4)
  - [ ] Add/extend request specs for GET `/users/edit` (authenticated success, unauthenticated redirect to sign-in).
  - [ ] Add spec for valid email update and persistence.
  - [ ] Add spec for valid password update with current password and post-update authenticated access.
  - [ ] Add spec for invalid current password update rejection with unchanged credentials.

## Dev Notes

### Architecture and Constraints

- Devise is the mandated auth solution (`devise` 5.x); use built-in registrations update behavior instead of custom auth logic. [Source: _bmad-output/planning-artifacts/architecture.md#Authentication & Security]
- Global `before_action :authenticate_user!` is already in `ApplicationController`; `/users/edit` remains accessible for authenticated users via Devise controller flow. [Source: _bmad-output/planning-artifacts/architecture.md#Process Patterns]
- Use only `flash[:notice]` and `flash[:alert]`; avoid custom flash keys. [Source: _bmad-output/planning-artifacts/architecture.md#Enforcement Guidelines]
- Validation failures should render with `status: :unprocessable_entity` for Turbo compatibility. [Source: _bmad-output/planning-artifacts/architecture.md#Process Patterns]
- Password updates must remain bcrypt-backed and never exposed in URLs/logs (NFR6/NFR9). [Source: _bmad-output/planning-artifacts/epics.md#Requirements Inventory]

### Previous Story Intelligence (1.3)

- Story 1.3 established auth gating and sign-out navigation; account settings link should be added to the same authenticated nav area for consistency.
- Existing Devise session view and request spec patterns are now in place; follow the same structure and assertions style.
- `spec/support/devise.rb` already includes integration helpers for request specs; use `sign_in user` in authenticated scenarios.

### Project Structure Notes

- Expected touch points for this story:
  - `app/views/layouts/application.html.erb` (add account settings link for signed-in users)
  - `app/views/devise/registrations/edit.html.erb` (new account settings form)
  - `spec/requests/` request specs for account edit/update flows
  - Optional: `config/initializers/devise.rb` only if existing defaults block AC behavior (avoid changes unless necessary)
- Do **not** create a custom Devise registrations controller unless defaults demonstrably fail the acceptance criteria.

### Testing Standards

- Use RSpec request specs plus FactoryBot user factories.
- Prefer flow-level assertions that verify both redirect/status behavior and persisted data changes.
- Keep test style aligned with existing registration/session request specs. [Source: _bmad-output/planning-artifacts/architecture.md#Testing Framework]

### References

- Epic requirements: `_bmad-output/planning-artifacts/epics.md` (Epic 1, Story 1.4)
- FR coverage map: `_bmad-output/planning-artifacts/epics.md#FR Coverage Map`
- Auth/process/enforcement patterns: `_bmad-output/planning-artifacts/architecture.md#Authentication & Security`, `_bmad-output/planning-artifacts/architecture.md#Process Patterns`, `_bmad-output/planning-artifacts/architecture.md#Enforcement Guidelines`
- Prior implementation context: `_bmad-output/implementation-artifacts/1-3-user-sign-in-sign-out.md`

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex (gpt-5.3-codex)

### Debug Log References

### Completion Notes List

- Story context generated from Epic 1 / Story 1.4 with architecture and prior-story implementation references.
- Ready for dev implementation.

### File List

- `_bmad-output/implementation-artifacts/1-4-account-details-management.md` (this story)

## Change Log

- 2026-04-27: Story 1.4 created — Account Details Management context prepared for development.
