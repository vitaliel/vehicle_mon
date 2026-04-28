class AddColumnsToServiceLogEntries < ActiveRecord::Migration[8.1]
  def up
    if select_value("SELECT 1 FROM service_log_entries LIMIT 1")
      raise ActiveRecord::MigrationError, <<~MSG.squish
        Cannot apply non-null service log columns: existing service_log_entries rows need a backfill strategy.
      MSG
    end

    add_reference :service_log_entries, :service_type, null: false, foreign_key: true, index: true
    add_column :service_log_entries, :serviced_on, :date, null: false
    add_column :service_log_entries, :mileage_at_service, :integer, null: false
    add_column :service_log_entries, :service_center, :string, null: false
    add_column :service_log_entries, :parts_cost, :decimal, precision: 10, scale: 2, null: false, default: 0
    add_column :service_log_entries, :labour_cost, :decimal, precision: 10, scale: 2, null: false, default: 0
    add_column :service_log_entries, :notes, :text
  end

  def down
    remove_column :service_log_entries, :notes
    remove_column :service_log_entries, :labour_cost
    remove_column :service_log_entries, :parts_cost
    remove_column :service_log_entries, :service_center
    remove_column :service_log_entries, :mileage_at_service
    remove_column :service_log_entries, :serviced_on
    remove_reference :service_log_entries, :service_type, foreign_key: true, index: true
  end
end
