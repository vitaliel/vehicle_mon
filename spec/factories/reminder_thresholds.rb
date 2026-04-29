FactoryBot.define do
  factory :reminder_threshold do
    association :vehicle
    association :service_type
    mileage_interval { 10_000 }
    time_interval_months { 12 }
  end
end
