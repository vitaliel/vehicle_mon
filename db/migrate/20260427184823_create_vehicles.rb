class CreateVehicles < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :make
      t.string :model
      t.integer :year
      t.integer :current_mileage

      t.timestamps
    end
  end
end
