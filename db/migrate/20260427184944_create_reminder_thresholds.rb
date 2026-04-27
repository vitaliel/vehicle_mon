class CreateReminderThresholds < ActiveRecord::Migration[8.1]
  def change
    create_table :reminder_thresholds do |t|
      t.references :vehicle, null: false, foreign_key: true

      t.timestamps
    end
  end
end
