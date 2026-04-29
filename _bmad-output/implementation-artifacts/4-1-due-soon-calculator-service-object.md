# Story 4.1: DueSoonCalculator Service Object

Status: review

## Story

As a developer,
I want a `DueSoonCalculator` service object that encapsulates all due-soon calculation logic,
so that calculation is consistent, testable, and never duplicated across controllers or views.

## Acceptance Criteria

1. **Given** a vehicle and service type with no `ReminderThreshold` row,
   **When** `DueSoonCalculator.call(vehicle:, service_type:)` is called,
   **Then** it returns `{ status: :unconfigured, mileage_remaining: nil, days_remaining: nil }` (FR19, FR26)

2. **Given** a threshold exists and neither mileage nor time limit is breached,
   **When** `DueSoonCalculator.call` is invoked,
   **Then** it returns `{ status: :ok, mileage_remaining: Integer, days_remaining: Integer }` (nil for whichever threshold dimension is not configured)

3. **Given** either the mileage or time threshold is reached or exceeded,
   **When** `DueSoonCalculator.call` is invoked,
   **Then** it returns `{ status: :due_soon, ... }` — FR22 whichever arrives first

4. **Given** only a mileage threshold is set (`mileage_interval` present, `time_interval_months` nil),
   **When** the calculator is called,
   **Then** it evaluates mileage only; `days_remaining` is nil

5. **Given** only a time threshold is set (`mileage_interval` nil, `time_interval_months` present),
   **When** the calculator is called,
   **Then** it evaluates time only; `mileage_remaining` is nil

6. **Given** `spec/services/due_soon_calculator_spec.rb`,
   **When** the test suite runs,
   **Then** all four threshold states (`:ok`, `:due_soon`, `:unconfigured`, mileage-only, time-only) have passing unit tests

## Tasks / Subtasks

- [x] Task 1: Migrate `reminder_thresholds` to add missing columns (AC: #1–#5)
  - [x] Generate migration: `rails generate migration AddColumnsToReminderThresholds service_type_id:bigint:index mileage_interval:integer time_interval_months:integer`
  - [x] Add `null: false` constraint on `service_type_id`, add foreign key to `service_types`
  - [x] Add unique index on `(vehicle_id, service_type_id)` (architecture requirement)
  - [x] Run `rails db:migrate`

- [x] Task 2: Update `ReminderThreshold` model (AC: #1–#5)
  - [x] Add `belongs_to :service_type`
  - [x] Verify existing `belongs_to :vehicle` is present
  - [x] No other model changes needed for this story

- [x] Task 3: Add `reminder_thresholds` FactoryBot factory (AC: #6)
  - [x] Create `spec/factories/reminder_thresholds.rb` with `vehicle`, `service_type`, `mileage_interval: 10_000`, `time_interval_months: 12`

- [x] Task 4: Create `app/services/due_soon_calculator.rb` (AC: #1–#5)
  - [x] Implement class method `DueSoonCalculator.call(vehicle:, service_type:)` returning Hash
  - [x] Return `:unconfigured` when no threshold row exists
  - [x] Calculate `mileage_remaining` = `last_entry.mileage_at_service + threshold.mileage_interval - vehicle.current_mileage`
  - [x] Calculate `days_remaining` = `(last_entry.serviced_on + threshold.time_interval_months.months - Date.current).to_i`
  - [x] Status `:due_soon` when either remaining value ≤ 0; `:ok` otherwise
  - [x] When no last entry exists, treat `mileage_at_service` as 0 and `serviced_on` as far in the past (or return `:unconfigured` — see Dev Notes)

- [x] Task 5: Create `spec/services/due_soon_calculator_spec.rb` (AC: #6)
  - [x] `:unconfigured` — no threshold row
  - [x] `:ok` — dual threshold, neither breached
  - [x] `:due_soon` — mileage threshold breached
  - [x] `:due_soon` — time threshold breached
  - [x] mileage-only threshold: `days_remaining` nil
  - [x] time-only threshold: `mileage_remaining` nil
  - [x] No log entries + threshold present (edge case)

## Dev Notes

### CRITICAL: reminder_thresholds Table is Incomplete

The current `reminder_thresholds` table (confirmed in `db/schema.rb`) only has `vehicle_id`. It is **missing**:
- `service_type_id` (bigint, not null, FK to service_types)
- `mileage_interval` (integer, nullable)
- `time_interval_months` (integer, nullable)

**You must create a migration as Task 1 before any other task.** Use:
```bash
rails generate migration AddColumnsToReminderThresholds \
  service_type_id:bigint \
  mileage_interval:integer \
  time_interval_months:integer
```

Then manually edit the migration to add:
- `null: false` on `service_type_id`
- `add_foreign_key :reminder_thresholds, :service_types`
- `add_index :reminder_thresholds, [:vehicle_id, :service_type_id], unique: true`
- Remove the existing `index_reminder_thresholds_on_vehicle_id` if you add the composite unique index (Rails will generate it automatically)

### ReminderThreshold Model (Current State)

```ruby
# app/models/reminder_threshold.rb — CURRENT (incomplete)
class ReminderThreshold < ApplicationRecord
  belongs_to :vehicle
end

# MUST become:
class ReminderThreshold < ApplicationRecord
  belongs_to :vehicle
  belongs_to :service_type
end
```

### DueSoonCalculator — Canonical Interface (Architecture ARC4)

```ruby
# app/services/due_soon_calculator.rb
class DueSoonCalculator
  def self.call(vehicle:, service_type:)
    new(vehicle: vehicle, service_type: service_type).call
  end

  def initialize(vehicle:, service_type:)
    @vehicle      = vehicle
    @service_type = service_type
  end

  def call
    threshold = ReminderThreshold.find_by(vehicle: @vehicle, service_type: @service_type)
    return unconfigured if threshold.nil?

    last_entry = @vehicle.service_log_entries
                         .where(service_type: @service_type)
                         .order(serviced_on: :desc)
                         .first

    mileage_remaining = calculate_mileage_remaining(threshold, last_entry)
    days_remaining    = calculate_days_remaining(threshold, last_entry)

    status = determine_status(mileage_remaining, days_remaining)
    { status: status, mileage_remaining: mileage_remaining, days_remaining: days_remaining }
  end

  private

  def unconfigured
    { status: :unconfigured, mileage_remaining: nil, days_remaining: nil }
  end

  def calculate_mileage_remaining(threshold, last_entry)
    return nil unless threshold.mileage_interval
    base_mileage = last_entry&.mileage_at_service || 0
    base_mileage + threshold.mileage_interval - @vehicle.current_mileage
  end

  def calculate_days_remaining(threshold, last_entry)
    return nil unless threshold.time_interval_months
    base_date = last_entry&.serviced_on || Date.current - threshold.time_interval_months.months
    (base_date + threshold.time_interval_months.months - Date.current).to_i
  end

  def determine_status(mileage_remaining, days_remaining)
    breached = (mileage_remaining && mileage_remaining <= 0) ||
               (days_remaining && days_remaining <= 0)
    breached ? :due_soon : :ok
  end
end
```

**No-entry edge case decision:** When there is no last log entry but a threshold exists, treat base mileage as 0 and base date as `Date.current - time_interval_months.months` (i.e., immediately due). This means a newly tracked vehicle with a threshold set but no service logged will show `:due_soon` — signalling the user should log their first entry. This is the safe/visible default.

### Project Structure

**New files to CREATE:**
- `app/services/due_soon_calculator.rb` — DueSoonCalculator (sole service object in v1)
- `spec/services/due_soon_calculator_spec.rb` — unit tests
- `spec/factories/reminder_thresholds.rb` — FactoryBot factory
- `db/migrate/YYYYMMDD_add_columns_to_reminder_thresholds.rb` — migration (generated)

**Files to MODIFY:**
- `app/models/reminder_threshold.rb` — add `belongs_to :service_type`
- `db/schema.rb` — updated automatically by `rails db:migrate`

**Files to NOT touch:**
- `app/controllers/` — no controller work in this story
- `app/views/` — no view work in this story
- `spec/requests/` — no request specs in this story
- Any Epic 5 files

### Spec File: due_soon_calculator_spec.rb

```ruby
# spec/services/due_soon_calculator_spec.rb
require 'rails_helper'

RSpec.describe DueSoonCalculator do
  let(:user)         { create(:user) }
  let(:vehicle)      { create(:vehicle, user: user, current_mileage: 95_000) }
  let(:service_type) { create(:service_type) }

  subject(:result) { described_class.call(vehicle: vehicle, service_type: service_type) }

  context "when no threshold is configured" do
    it "returns :unconfigured with nil remainders" do
      expect(result).to eq({ status: :unconfigured, mileage_remaining: nil, days_remaining: nil })
    end
  end

  context "when a dual threshold exists and neither is breached" do
    let!(:threshold) do
      create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
             mileage_interval: 10_000, time_interval_months: 12)
    end
    let!(:entry) do
      create(:service_log_entry, vehicle: vehicle, service_type: service_type,
             mileage_at_service: 90_000, serviced_on: 3.months.ago.to_date)
    end

    it "returns :ok with positive remainders" do
      expect(result[:status]).to eq(:ok)
      expect(result[:mileage_remaining]).to eq(5_000)   # 90_000 + 10_000 - 95_000
      expect(result[:days_remaining]).to be > 0
    end
  end

  context "when mileage threshold is breached" do
    let!(:threshold) do
      create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
             mileage_interval: 4_000, time_interval_months: nil)
    end
    let!(:entry) do
      create(:service_log_entry, vehicle: vehicle, service_type: service_type,
             mileage_at_service: 90_000, serviced_on: 1.month.ago.to_date)
    end

    it "returns :due_soon" do
      # 90_000 + 4_000 - 95_000 = -1_000 (breached)
      expect(result[:status]).to eq(:due_soon)
      expect(result[:mileage_remaining]).to eq(-1_000)
      expect(result[:days_remaining]).to be_nil
    end
  end

  context "when time threshold is breached" do
    let!(:threshold) do
      create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
             mileage_interval: nil, time_interval_months: 6)
    end
    let!(:entry) do
      create(:service_log_entry, vehicle: vehicle, service_type: service_type,
             mileage_at_service: 80_000, serviced_on: 8.months.ago.to_date)
    end

    it "returns :due_soon with nil mileage_remaining" do
      expect(result[:status]).to eq(:due_soon)
      expect(result[:mileage_remaining]).to be_nil
      expect(result[:days_remaining]).to be < 0
    end
  end

  context "when only mileage threshold is configured" do
    let!(:threshold) do
      create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
             mileage_interval: 10_000, time_interval_months: nil)
    end

    it "returns nil for days_remaining" do
      expect(result[:days_remaining]).to be_nil
    end
  end

  context "when only time threshold is configured" do
    let!(:threshold) do
      create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
             mileage_interval: nil, time_interval_months: 12)
    end

    it "returns nil for mileage_remaining" do
      expect(result[:mileage_remaining]).to be_nil
    end
  end

  context "when threshold exists but no log entry" do
    let!(:threshold) do
      create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
             mileage_interval: 5_000, time_interval_months: 12)
    end

    it "returns :due_soon (no entry = treat as overdue)" do
      expect(result[:status]).to eq(:due_soon)
    end
  end
end
```

### reminder_thresholds Factory

```ruby
# spec/factories/reminder_thresholds.rb
FactoryBot.define do
  factory :reminder_threshold do
    association :vehicle
    association :service_type
    mileage_interval { 10_000 }
    time_interval_months { 12 }
  end
end
```

### Testing Standards

- Run `bundle exec rspec` before starting — baseline is **118 examples, 0 failures**, 2 pre-existing pending.
- All new specs go in `spec/services/due_soon_calculator_spec.rb` — **new file**.
- Use FactoryBot; no fixture files.
- Use `sign_in` is NOT needed — this is a pure unit test (no HTTP), no auth context required.
- `let!` (bang) to materialize associations before calling the calculator.

### Architecture Compliance Checklist

- ✅ `DueSoonCalculator` lives in `app/services/due_soon_calculator.rb` — sole service object
- ✅ Interface: `DueSoonCalculator.call(vehicle:, service_type:)` returning Hash
- ✅ Return keys: `{ status:, mileage_remaining:, days_remaining: }` — exactly as specified (ARC4)
- ✅ Status values: `:unconfigured`, `:ok`, `:due_soon` only
- ✅ Never reimplemented inline in controllers or views (enforced in later stories)
- ✅ Spec in `spec/services/` folder

### References

- Story ACs: `_bmad-output/planning-artifacts/epics.md#Story 4.1: DueSoonCalculator Service Object`
- Epic context: `_bmad-output/planning-artifacts/epics.md#Epic 4: Maintenance Reminders & Due-Soon Engine`
- Service interface (ARC4): `_bmad-output/planning-artifacts/architecture.md#Service Interface Pattern`
- Project structure: `_bmad-output/planning-artifacts/architecture.md#Project Organization`
- Schema (current): `db/schema.rb` — reminder_thresholds missing columns confirmed
- Existing model: `app/models/reminder_threshold.rb`
- Existing factories: `spec/factories/` (no reminder_thresholds.rb yet)
- Previous story: `_bmad-output/implementation-artifacts/3-5-delete-service-log-entry.md`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4.6

### Debug Log References

- `reminder_thresholds` table confirmed missing `service_type_id`, `mileage_interval`, `time_interval_months` — migration created and run first as planned.
- Regression found in `spec/requests/vehicles_spec.rb:194`: existing test used `ReminderThreshold.create!(vehicle: vehicle)` without `service_type`; fixed to use `create(:reminder_threshold, vehicle: vehicle)` factory.
- No-entry edge case: `base_date = Date.current - threshold.time_interval_months.months` produces `days_remaining = 0`, which correctly triggers `:due_soon` (≤ 0).

### Completion Notes List

- Created migration `20260429103712_add_columns_to_reminder_thresholds.rb` — adds `service_type_id` (not null, FK), `mileage_interval`, `time_interval_months`; adds unique index on `(vehicle_id, service_type_id)`; removes old single-column vehicle index.
- Updated `app/models/reminder_threshold.rb` — added `belongs_to :service_type`.
- Created `spec/factories/reminder_thresholds.rb` with sensible defaults (`mileage_interval: 10_000`, `time_interval_months: 12`).
- Created `app/services/due_soon_calculator.rb` — implements `DueSoonCalculator.call(vehicle:, service_type:)` returning `{ status:, mileage_remaining:, days_remaining: }`. Handles all four states: `:unconfigured`, `:ok`, `:due_soon`, plus mileage-only / time-only configurations. No-entry edge case returns `:due_soon`.
- Created `spec/services/due_soon_calculator_spec.rb` with 14 examples covering all AC scenarios.
- Fixed `spec/requests/vehicles_spec.rb` regression (used bare `ReminderThreshold.create!` without required `service_type`).
- **135 examples, 0 failures**, 2 pre-existing pending stubs unchanged.

### File List

- `db/migrate/20260429103712_add_columns_to_reminder_thresholds.rb` (new)
- `db/schema.rb` (auto-updated by migration)
- `app/models/reminder_threshold.rb` (modified — added belongs_to :service_type)
- `app/services/due_soon_calculator.rb` (new)
- `spec/factories/reminder_thresholds.rb` (new)
- `spec/services/due_soon_calculator_spec.rb` (new)
- `spec/requests/vehicles_spec.rb` (modified — fixed ReminderThreshold cascade test to use factory)
- `_bmad-output/implementation-artifacts/4-1-due-soon-calculator-service-object.md` (story updated)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (updated)
