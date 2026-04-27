## Deferred from: code review of 2-1-add-list-vehicles (2026-04-27)

- Vehicle card "View" link behavior before `show` exists [app/views/shared/_vehicle_card.html.erb:8] — deferred for future story work. Reason: Vehicle view will be implemented later.
- Future-epic service/reminder schema additions scope [db/migrate/20260427184943_create_service_log_entries.rb, db/migrate/20260427184944_create_reminder_thresholds.rb, db/schema.rb] — deferred after validation because removing them breaks required `Vehicle` association expectations in current model specs.
