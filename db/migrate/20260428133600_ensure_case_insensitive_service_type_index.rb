class EnsureCaseInsensitiveServiceTypeIndex < ActiveRecord::Migration[8.1]
  def up
    remove_index :service_types, name: "index_service_types_on_name", if_exists: true
    add_index :service_types, "LOWER(name)", unique: true, name: "index_service_types_on_lower_name", if_not_exists: true
  end

  def down
    remove_index :service_types, name: "index_service_types_on_lower_name", if_exists: true
    add_index :service_types, :name, unique: true, if_not_exists: true
  end
end
