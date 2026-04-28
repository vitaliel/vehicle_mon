class AddColumnsToServiceLogEntries < ActiveRecord::Migration[8.1]
  def change
    add_reference :service_log_entries, :service_type, null: false, foreign_key: true, index: true
    add_column :service_log_entries, :serviced_on, :date, null: false
    add_column :service_log_entries, :mileage_at_service, :integer, null: false
    add_column :service_log_entries, :service_center, :string, null: false
    add_column :service_log_entries, :parts_cost, :decimal, precision: 10, scale: 2, null: false, default: 0
    add_column :service_log_entries, :labour_cost, :decimal, precision: 10, scale: 2, null: false, default: 0
    add_column :service_log_entries, :notes, :text
  end
end
