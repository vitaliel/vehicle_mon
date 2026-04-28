class CreateServiceTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :service_types do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :service_types, "LOWER(name)", unique: true, name: "index_service_types_on_lower_name"
  end
end
