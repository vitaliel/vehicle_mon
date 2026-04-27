# Story 1.3: User Sign In & Sign Out

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a registered user,
I want to sign in with my email and password, and sign out when done,
so that my data is secure and only I can access it.

## Acceptance Criteria

1. **Given** I am not signed in, **When** I visit `/users/sign_in` and submit valid credentials, **Then** I am signed in and redirected to the dashboard (root path), **And** a `flash[:notice]` welcome message is shown.

2. **Given** I am not signed in, **When** I visit any protected route, **Then** I am redirected to the sign-in page (all non-Devise routes protected — NFR5).

3. **Given** I submit invalid credentials on the sign-in form, **When** the form is submitted, **Then** I see a `flash[:alert]` error message, **And** I remain on the sign-in page (Devise renders the `new` session view again).

4. **Given** I am signed in, **When** I click sign out (DELETE `/users/sign_out`), **Then** my session token is invalidated (NFR8), **And** I am redirected to the sign-in page (`/users/sign_in`), **And** visiting any protected route again redirects me back to sign-in.

## Tasks / Subtasks

- [x] Task 1: Enforce global authentication in ApplicationController (AC: #2)
  - [x] Add `before_action :authenticate_user!` to `ApplicationController` — applies to all controllers globally
  - [x] Add `rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found` and private `handle_not_found` method that redirects to `root_path` with `alert: "Record not found."` (ARC10)
  - [x] Do NOT add `skip_before_action` anywhere — Devise session/registration controllers are exempted automatically by Devise
  - [x] Verify `pages#index` (root) is accessible to authenticated users only (unauthenticated → redirect to sign-in)

- [x] Task 2: Customize sign-in view with Bootstrap layout (AC: #1, #3)
  - [x] Create `app/views/devise/sessions/new.html.erb` with Bootstrap form layout matching the registration view style
  - [x] Form must use `f.label` + `f.email_field` / `f.password_field` with `class: "form-control"` and `class: "form-label"` (NFR11 — visible associated labels)
  - [x] Include `render "devise/shared/links"` for navigation links to registration/password reset
  - [x] Do NOT create a Devise sessions controller override — default Devise `SessionsController` handles all logic
  - [x] Ensure `form_for(resource, as: resource_name, url: session_path(resource_name))` — exact Devise helper pattern

- [x] Task 3: Verify sign-out behavior and flash messaging (AC: #4)
  - [x] Confirm `Devise.sign_out_via` is configured — Devise 5.x defaults to DELETE; no override needed unless the default was changed
  - [x] Verify the sign-out link/button uses `link_to "Sign out", destroy_user_session_path, data: { turbo_method: :delete }` — required for Turbo DELETE request
  - [x] Add sign-out navigation link to application layout (`app/views/layouts/application.html.erb`) — display only when `user_signed_in?`
  - [x] After sign-out Devise redirects to `root_path` by default; configure `after_sign_out_path_for` in `ApplicationController` to redirect to `new_user_session_path` instead (NFR8 — explicit sign-in redirect)
  - [x] Verify flash[:notice] is shown after successful sign-in (Devise sets this automatically); no custom flash override needed

- [x] Task 4: Write request specs for all sign-in/sign-out flows (AC: #1, #2, #3, #4)
  - [x] Create `spec/requests/sessions_spec.rb`
  - [x] Spec: GET `/users/sign_in` → 200 OK (accessible without authentication)
  - [x] Spec: Sign-in form renders email and password fields with labels (NFR11)
  - [x] Spec: POST `/users/sign_in` with valid credentials → redirect to root + flash[:notice] present
  - [x] Spec: POST `/users/sign_in` with invalid credentials → remain on sign-in page (200 or 422) + flash[:alert] present
  - [x] Spec: Authenticated user DELETE `/users/sign_out` → redirect to sign-in + session cleared
  - [x] Spec: GET any protected route (e.g., `root_path`) without authentication → redirect to `/users/sign_in` (AC #2)
  - [x] Use `create(:user)` factory and `sign_in(user)` helper (from `spec/support/devise.rb` — IntegrationHelpers already configured)
  - [x] Run full suite to confirm zero regressions after global `authenticate_user!` is added

## Dev Notes

### Authentication Enforcement

`before_action :authenticate_user!` MUST be added to `ApplicationController`. This is the ARC3 architecture mandate. Devise **automatically** skips this callback for its own controllers (`Devise::SessionsController`, `Devise::RegistrationsController`, etc.) — no `skip_before_action` is needed.

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

  allow_browser versions: :modern
  stale_when_importmap_changes

  private

  def handle_not_found
    redirect_to root_path, alert: "Record not found."
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end
end
```

`after_sign_out_path_for` can live in `ApplicationController` or a custom Devise sessions controller. Placing it in `ApplicationController` is simpler and avoids creating a custom controller override. [Source: _bmad-output/planning-artifacts/architecture.md#Process Patterns]

### Sign-In View Pattern

Match the registration view's Bootstrap layout exactly:

```erb
<%# app/views/devise/sessions/new.html.erb %>
<div class="row justify-content-center mt-5">
  <div class="col-md-6 col-lg-4">
    <h2 class="mb-4">Sign In</h2>

    <%= form_for(resource, as: resource_name, url: session_path(resource_name)) do |f| %>
      <div class="mb-3">
        <%= f.label :email, class: "form-label" %>
        <%= f.email_field :email, autofocus: true, autocomplete: "email", class: "form-control" %>
      </div>

      <div class="mb-3">
        <%= f.label :password, class: "form-label" %>
        <%= f.password_field :password, autocomplete: "current-password", class: "form-control" %>
      </div>

      <div class="d-grid">
        <%= f.submit "Sign in", class: "btn btn-primary" %>
      </div>
    <% end %>

    <div class="mt-3 text-center">
      <%= render "devise/shared/links" %>
    </div>
  </div>
</div>
```

Note: Devise handles all sign-in logic in its default `SessionsController`. Invalid credentials trigger a `flash[:alert]` automatically via `config.authentication_keys`. Do **not** override `Devise::SessionsController` unless the default behavior is insufficient.

### Sign-Out Navigation Link

Add to `app/views/layouts/application.html.erb` inside `<body>`, before or as part of a nav bar:

```erb
<% if user_signed_in? %>
  <%= link_to "Sign out", destroy_user_session_path,
        data: { turbo_method: :delete },
        class: "btn btn-outline-secondary btn-sm" %>
<% end %>
```

`data: { turbo_method: :delete }` is **required** with Turbo — without it the request defaults to GET and sign-out silently fails. [Source: Turbo + Devise integration pattern]

### Flash Key Contract

- Sign-in success: Devise automatically sets `flash[:notice]` (e.g., "Signed in successfully.")
- Sign-in failure: Devise automatically sets `flash[:alert]` (e.g., "Invalid Email or password.")
- Sign-out: Devise automatically sets `flash[:notice]` (e.g., "Signed out successfully.")
- These match the existing flash partial (`shared/_flash_messages`): `notice` → `alert-success`, `alert` → `alert-danger`
- Do **not** set custom flash messages unless overriding Devise defaults [Source: _bmad-output/planning-artifacts/architecture.md#Enforcement Guidelines]

### Important: Impact of Global `authenticate_user!`

Adding `before_action :authenticate_user!` to `ApplicationController` will affect the existing `pages#index` (root route). After this change:
- Unauthenticated visitors hitting root will redirect to `/users/sign_in` — this is the correct behavior per FR2/NFR5
- Existing spec `spec/requests/pages_spec.rb` tests GET root — it will now redirect (302) instead of returning 200 for unauthenticated requests. **Update that spec** to either sign in first or assert redirect behavior
- The `before_action :authenticate_user!` line should be placed before `allow_browser` and `stale_when_importmap_changes` for clarity, or after — Rails processes them in order but for before_action hooks, order relative to those helpers is irrelevant

### Testing Patterns

Use `spec/support/devise.rb` integration helpers (already configured):
```ruby
# For request specs — sign in a user before protected route tests:
let(:user) { create(:user) }

before { sign_in user }

# Or use Devise helpers directly:
post user_session_path, params: { user: { email: user.email, password: user.password } }
```

The `Devise::Test::IntegrationHelpers` module (included for `type: :request`) provides `sign_in` and `sign_out` helpers. [Source: spec/support/devise.rb]

### Regression Risk

The most critical regression risk is the `pages_spec.rb` — it likely tests root path for unauthenticated access. After adding `authenticate_user!`:
- Unauthenticated GET to root returns 302 (redirect to sign-in), not 200
- Update the existing page spec accordingly; do not delete it

### Project Structure Notes

Files to touch for this story:
- `app/controllers/application_controller.rb` — add `before_action :authenticate_user!`, `rescue_from`, and `after_sign_out_path_for`
- `app/views/devise/sessions/new.html.erb` — NEW: Bootstrap sign-in form (Devise sessions views directory doesn't exist yet)
- `app/views/layouts/application.html.erb` — add sign-out link visible to `user_signed_in?` users
- `spec/requests/sessions_spec.rb` — NEW: sign-in/sign-out request specs
- `spec/requests/pages_spec.rb` — UPDATE: adjust unauthenticated root path expectation from 200 to 302 redirect

Do NOT:
- Create a custom Devise sessions controller
- Add `skip_before_action :authenticate_user!` to any controller (Devise exempts itself)
- Modify `config/initializers/devise.rb` (already configured for this app)
- Change `Devise.sign_out_via` (default is DELETE, correct for Turbo)

### References

- Epic requirements: `_bmad-output/planning-artifacts/epics.md` (Epic 1, Story 1.3, lines ~211–238)
- Auth enforcement pattern: `_bmad-output/planning-artifacts/architecture.md#Authentication & Security`
- Process patterns (after_sign_out, flash keys): `_bmad-output/planning-artifacts/architecture.md#Process Patterns`
- Enforcement guidelines: `_bmad-output/planning-artifacts/architecture.md#Enforcement Guidelines`
- Previous story patterns (Bootstrap form, shared partials): `_bmad-output/implementation-artifacts/1-2-user-registration.md`
- Devise test helpers already configured: `spec/support/devise.rb`
- User factory available: `spec/factories/users.rb`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4.6

### Debug Log References

### Completion Notes List

- Story context generated from Epic 1 / Story 1.3 with full architecture, previous story, and codebase analysis.
- Ready for dev implementation.
- ✅ Task 1 complete: `before_action :authenticate_user!`, `rescue_from ActiveRecord::RecordNotFound`, and `after_sign_out_path_for` added to ApplicationController.
- ✅ Task 2 complete: `app/views/devise/sessions/new.html.erb` created with Bootstrap layout, labeled email/password fields, and Devise shared links.
- ✅ Task 3 complete: Sign-out nav link added to application layout with `data: { turbo_method: :delete }`; `after_sign_out_path_for` redirects to sign-in page.
- ✅ Task 4 complete: `spec/requests/sessions_spec.rb` created (8 new specs covering all ACs); `spec/requests/pages_spec.rb` updated for auth enforcement. 27 examples, 0 failures.

### File List

- `app/controllers/application_controller.rb` (modified — authenticate_user!, rescue_from, after_sign_out_path_for)
- `app/views/devise/sessions/new.html.erb` (created — Bootstrap sign-in form)
- `app/views/layouts/application.html.erb` (modified — sign-out nav link)
- `spec/requests/sessions_spec.rb` (created — sign-in/sign-out request specs)
- `spec/requests/pages_spec.rb` (modified — updated for auth enforcement)
- `_bmad-output/implementation-artifacts/1-3-user-sign-in-sign-out.md` (this story)

## Change Log

- 2026-04-27: Story 1.3 created — User Sign In & Sign Out context file ready for development.
- 2026-04-27: Story 1.3 implemented — global auth enforcement, Bootstrap sign-in view, sign-out nav link, request specs. 27 examples, 0 failures.
