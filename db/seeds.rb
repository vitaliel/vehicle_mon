# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Service Type catalog — global, non-user-owned seed data
canonical_service_types = [
  "Engine Oil",
  "Spark Plugs",
  "Air Filter",
  "Brake Pads",
  "Transmission Fluid",
  "Tires"
]

ServiceType.select("LOWER(name) AS normalized_name, MIN(id) AS keep_id").group("LOWER(name)").each do |row|
  normalized_name = row.attributes["normalized_name"]
  keep_id = row.attributes["keep_id"]
  ServiceType.where("LOWER(name) = ? AND id != ?", normalized_name, keep_id).delete_all
end

canonical_service_types.each do |name|
  service_type = ServiceType.where("LOWER(name) = ?", name.downcase).first_or_initialize
  service_type.name = name
  service_type.save! if service_type.new_record? || service_type.changed?
end

ServiceType.where.not("LOWER(name) IN (?)", canonical_service_types.map(&:downcase)).delete_all
