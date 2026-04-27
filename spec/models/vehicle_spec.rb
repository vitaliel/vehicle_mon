require 'rails_helper'

RSpec.describe Vehicle, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:service_log_entries).dependent(:destroy) }
    it { is_expected.to have_many(:reminder_thresholds).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:make) }
    it { is_expected.to validate_presence_of(:model) }
    it { is_expected.to validate_numericality_of(:year).only_integer.is_greater_than(1885) }
    it { is_expected.to validate_numericality_of(:current_mileage).only_integer.is_greater_than_or_equal_to(0) }
  end
end
