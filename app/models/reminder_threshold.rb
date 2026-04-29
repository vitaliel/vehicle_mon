class ReminderThreshold < ApplicationRecord
  belongs_to :vehicle
  belongs_to :service_type

  validates :mileage_interval, numericality: { greater_than: 0, allow_nil: true }
  validates :time_interval_months, numericality: { greater_than: 0, allow_nil: true }
end
