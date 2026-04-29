class AddColumnsToReminderThresholds < ActiveRecord::Migration[8.1]
  def change
    add_column :reminder_thresholds, :service_type_id, :bigint, null: false
    add_column :reminder_thresholds, :mileage_interval, :integer
    add_column :reminder_thresholds, :time_interval_months, :integer
    add_foreign_key :reminder_thresholds, :service_types
    add_index :reminder_thresholds, [ :vehicle_id, :service_type_id ], unique: true
    remove_index :reminder_thresholds, :vehicle_id
  end
end
