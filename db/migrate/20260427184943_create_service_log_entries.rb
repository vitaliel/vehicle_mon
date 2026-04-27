class CreateServiceLogEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :service_log_entries do |t|
      t.references :vehicle, null: false, foreign_key: true

      t.timestamps
    end
  end
end
