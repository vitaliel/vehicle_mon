require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe "validations" do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should allow_value("valid@example.com").for(:email) }
    it { should_not allow_value("not-an-email").for(:email) }
    it { should_not allow_value("").for(:email) }
  end

  describe "Devise modules" do
    it "is database authenticatable" do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it "is registerable" do
      expect(User.devise_modules).to include(:registerable)
    end

    it "is validatable" do
      expect(User.devise_modules).to include(:validatable)
    end
  end
end
