class ServiceLogEntry < ApplicationRecord
  belongs_to :vehicle
  belongs_to :service_type

  validates :service_type, presence: true
  validates :serviced_on, presence: true
  validates :mileage_at_service, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :service_center, presence: true
  validates :parts_cost, numericality: { greater_than_or_equal_to: 0 }
  validates :labour_cost, numericality: { greater_than_or_equal_to: 0 }
end
