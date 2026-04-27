class Vehicle < ApplicationRecord
  belongs_to :user
  has_many :service_log_entries, dependent: :destroy
  has_many :reminder_thresholds, dependent: :destroy

  validates :make, presence: true
  validates :model, presence: true
  validates :year, numericality: { only_integer: true, greater_than: 1885, less_than_or_equal_to: Date.current.year + 1 }
  validates :current_mileage, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
