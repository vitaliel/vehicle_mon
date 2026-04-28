require 'rails_helper'

RSpec.describe ServiceType, type: :model do
  subject { build(:service_type) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end

  describe 'global catalog (no user ownership)' do
    it 'does not have a user_id column' do
      expect(ServiceType.column_names).not_to include('user_id')
    end
  end
end
