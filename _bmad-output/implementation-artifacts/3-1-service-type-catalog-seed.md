# Story 3.1: Service Type Catalog Seed

Status: ready-for-dev

## Story

As a developer,
I want the database seeded with the predefined service type catalog,
so that users can select service types when logging entries without any configuration.

## Acceptance Criteria

1. **Given** `rails db:seed` is run, **When** the seeds complete, **Then** exactly 6 service type records exist: Engine Oil, Spark Plugs, Air Filter, Brake Pads, Transmission Fluid, Tires, **And** running `db:seed` again does not create duplicates (idempotent).
2. **Given** the `ServiceType` model, **When** reviewed, **Then** it has no `user_id` column (global catalog, not user-owned, per architecture).

## Tasks / Subtasks

- [ ] Task 1: Add global `ServiceType` persistence model and schema (AC: #2)
  - [ ] Create migration `db/migrate/*_create_service_types.rb` with `service_types` table and `name` column (`null: false`).
  - [ ] Add a unique DB index on `service_types.name` to prevent duplicates and enforce seed idempotency at persistence level.
  - [ ] Create `app/models/service_type.rb` with validation for `name` presence and uniqueness.
  - [ ] Ensure the model is global (no `belongs_to :user`, no `user_id` column).

- [ ] Task 2: Implement idempotent seed data for the 6 canonical service types (AC: #1)
  - [ ] Update `db/seeds.rb` to create/find exactly these names: Engine Oil, Spark Plugs, Air Filter, Brake Pads, Transmission Fluid, Tires.
  - [ ] Use idempotent creation pattern (`find_or_create_by!`) so repeated `db:seed` runs do not create duplicates.
  - [ ] Keep seed naming and capitalization exactly aligned with acceptance criteria.

- [ ] Task 3: Add coverage for model constraints and seed idempotency (AC: #1, #2)
  - [ ] Add `spec/models/service_type_spec.rb` for validation coverage (presence and uniqueness of `name`).
  - [ ] Add/update `spec/factories/service_types.rb` factory for `ServiceType`.
  - [ ] Add a seed-focused spec (or equivalent test coverage pattern already used in repo) that verifies:
    - first seed run creates exactly 6 `ServiceType` records;
    - second seed run keeps count at 6 (no duplicates).

## Dev Notes

### Architecture & Critical Constraints

- `ServiceType` is explicitly global seed data in v1 and must remain non-user-owned. Do not add `user_id` in this story. [Source: _bmad-output/planning-artifacts/architecture.md#Data Architecture]
- Service catalog requirement is FR10/FR11 and is implemented through seeded data, later consumed by service log entry forms. [Source: _bmad-output/planning-artifacts/epics.md#Story 3.1: Service Type Catalog Seed]
- Follow Rails ActiveRecord migration conventions; no manual SQL schema manipulation. [Source: _bmad-output/planning-artifacts/architecture.md#Data Architecture]
- Keep naming conventions consistent: table `service_types`, model `ServiceType`, snake_case DB columns. [Source: _bmad-output/planning-artifacts/architecture.md#Naming Patterns]
- Do not scope `ServiceType` through `current_user`; this is one of the explicitly global data boundaries in architecture. [Source: _bmad-output/planning-artifacts/architecture.md#Architectural Boundaries]

### Implementation Guidance

- Current repository state already contains `service_log_entries` and `reminder_thresholds` tables but does **not** yet contain `service_types`; create-story should treat this story as the missing foundation for Epic 3.
- For deterministic behavior in tests/UI dropdowns, prefer querying service types ordered by name where relevant in future stories.
- Keep seed list centralized in `db/seeds.rb` for now (MVP simplicity); avoid introducing extra seed service objects.

### Project Structure Notes

Files to create:
- `app/models/service_type.rb`
- `db/migrate/*_create_service_types.rb`
- `spec/models/service_type_spec.rb`
- `spec/factories/service_types.rb`

Files to modify:
- `db/seeds.rb`

Files not to touch in this story:
- `app/controllers/**` (no controller behavior is part of Story 3.1)
- `app/services/due_soon_calculator.rb` (Epic 4 concern)

### References

- Story definition and ACs: `_bmad-output/planning-artifacts/epics.md#Story 3.1: Service Type Catalog Seed`
- Epic context: `_bmad-output/planning-artifacts/epics.md#Epic 3: Service History Logging`
- ServiceType global seed decision: `_bmad-output/planning-artifacts/architecture.md#Data Architecture`
- Naming and structural rules: `_bmad-output/planning-artifacts/architecture.md#Naming Patterns`
- Project boundaries and global data rule: `_bmad-output/planning-artifacts/architecture.md#Architectural Boundaries`
- Target file layout: `_bmad-output/planning-artifacts/architecture.md#Complete Project Directory Structure`

## Dev Agent Record

### Agent Model Used

GPT-5.3-Codex (gpt-5.3-codex)

### Debug Log References

### Completion Notes List

### File List

## Change Log

- 2026-04-28: Story 3.1 created — Service Type Catalog Seed context prepared for development.
