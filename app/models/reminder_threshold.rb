class ReminderThreshold < ApplicationRecord
  belongs_to :vehicle
  belongs_to :service_type

  validates :vehicle_id, :service_type_id, presence: true
  validates :service_type_id, uniqueness: { scope: :vehicle_id }
  validates :mileage_interval, numericality: { greater_than: 0, allow_nil: true }
  validates :time_interval_months, numericality: { greater_than: 0, allow_nil: true }
end
