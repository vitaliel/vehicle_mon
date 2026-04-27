FactoryBot.define do
  factory :vehicle do
    association :user
    make { "Toyota" }
    model { "Camry" }
    year { 2020 }
    current_mileage { 45_000 }
  end
end
