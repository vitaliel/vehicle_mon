require 'rails_helper'

RSpec.describe ServiceLogEntry, type: :model do
  subject(:entry) { build(:service_log_entry) }

  describe "associations" do
    it { is_expected.to belong_to(:vehicle) }
    it { is_expected.to belong_to(:service_type) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:service_type) }
    it { is_expected.to validate_presence_of(:serviced_on) }
    it { is_expected.to validate_presence_of(:service_center) }

    it { is_expected.to validate_numericality_of(:mileage_at_service).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:parts_cost).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:labour_cost).is_greater_than_or_equal_to(0) }
  end

  describe "optional fields" do
    it "is valid without notes" do
      entry.notes = nil
      expect(entry).to be_valid
    end
  end
end
