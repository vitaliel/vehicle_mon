require 'rails_helper'

RSpec.describe ReminderThreshold, type: :model do
  let(:vehicle)      { create(:vehicle) }
  let(:service_type) { create(:service_type) }

  describe "associations" do
    it { is_expected.to belong_to(:vehicle) }
    it { is_expected.to belong_to(:service_type) }
  end

  describe "validations" do
    it "is valid with mileage_interval only" do
      threshold = build(:reminder_threshold, vehicle: vehicle, service_type: service_type,
                        mileage_interval: 10_000, time_interval_months: nil)
      expect(threshold).to be_valid
    end

    it "is valid with time_interval_months only" do
      threshold = build(:reminder_threshold, vehicle: vehicle, service_type: service_type,
                        mileage_interval: nil, time_interval_months: 12)
      expect(threshold).to be_valid
    end

    it "is valid with both intervals set" do
      threshold = build(:reminder_threshold, vehicle: vehicle, service_type: service_type,
                        mileage_interval: 10_000, time_interval_months: 12)
      expect(threshold).to be_valid
    end

    it "is invalid when mileage_interval is 0 or negative" do
      threshold = build(:reminder_threshold, vehicle: vehicle, service_type: service_type,
                        mileage_interval: 0, time_interval_months: nil)
      expect(threshold).not_to be_valid
      expect(threshold.errors[:mileage_interval]).to be_present
    end

    it "is invalid when time_interval_months is 0 or negative" do
      threshold = build(:reminder_threshold, vehicle: vehicle, service_type: service_type,
                        mileage_interval: nil, time_interval_months: -1)
      expect(threshold).not_to be_valid
      expect(threshold.errors[:time_interval_months]).to be_present
    end

    it "allows nil for both intervals (controller prevents persistence)" do
      threshold = build(:reminder_threshold, vehicle: vehicle, service_type: service_type,
                        mileage_interval: nil, time_interval_months: nil)
      expect(threshold).to be_valid
    end
  end
end
