FactoryBot.define do
  factory :service_type do
    sequence(:name) { |n| "Service Type #{n}" }
  end
end
