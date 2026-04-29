## Deferred from: code review of 3-4-edit-service-log-entry (2026-04-28)

- **No optimistic locking on concurrent edits**: `@entry.update(entry_params)` has no `lock_version` guard. Two users editing the same entry simultaneously will silently overwrite each other's changes. Not introduced by this story — pre-existing architectural gap throughout the app.
- **`mileage_at_service` blank submission coerced to nil**: Model validates `numericality` but not `presence`. Rails coerces blank strings to `nil`, which passes numericality validation by default (no `allow_nil: false`). Could result in a null mileage value on update. Pre-existing model validation gap.

## Deferred from: code review of 2-1-add-list-vehicles (2026-04-27)

- Vehicle card "View" link behavior before `show` exists [app/views/shared/_vehicle_card.html.erb:8] — deferred for future story work. Reason: Vehicle view will be implemented later.
- Future-epic service/reminder schema additions scope [db/migrate/20260427184943_create_service_log_entries.rb, db/migrate/20260427184944_create_reminder_thresholds.rb, db/schema.rb] — deferred after validation because removing them breaks required `Vehicle` association expectations in current model specs.

## Deferred from: code review of 4-1-due-soon-calculator-service-object (2026-04-29)

- Migration can fail on existing rows because `service_type_id` is added as NOT NULL immediately [db/migrate/20260429103712_add_columns_to_reminder_thresholds.rb:3] — deferred by user request. Reason: skip case when migration can fail.

## Deferred from: code review of 4-4-recalculate-due-soon-on-data-changes (2026-04-29)

- Handle failed threshold destroy in blank-interval update path [app/controllers/reminder_thresholds_controller.rb:42] — controller currently assumes `@threshold.destroy` succeeds and always shows success notice; if destroy fails, user gets incorrect feedback. Pre-existing behavior.
