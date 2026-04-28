FactoryBot.define do
  factory :service_log_entry do
    association :vehicle
    association :service_type
    serviced_on { Date.today }
    mileage_at_service { 50_000 }
    service_center { "Quick Lube Center" }
    parts_cost { 25.00 }
    labour_cost { 50.00 }
    notes { nil }
  end
end
