require "rails_helper"

RSpec.describe DueSoonCalculator do
  let(:user)         { create(:user) }
  let(:vehicle)      { create(:vehicle, user: user, current_mileage: 95_000) }
  let(:service_type) { create(:service_type) }

  subject(:result) { described_class.call(vehicle: vehicle, service_type: service_type) }

  context "when no threshold is configured" do
    it "returns :unconfigured with nil remainders" do
      expect(result).to eq({ status: :unconfigured, mileage_remaining: nil, days_remaining: nil })
    end
  end

  context "when a dual threshold exists and neither is breached" do
    let!(:threshold) do
      create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
             mileage_interval: 10_000, time_interval_months: 12)
    end
    let!(:entry) do
      create(:service_log_entry, vehicle: vehicle, service_type: service_type,
             mileage_at_service: 90_000, serviced_on: 3.months.ago.to_date)
    end

    it "returns :ok" do
      expect(result[:status]).to eq(:ok)
    end

    it "calculates mileage_remaining correctly" do
      # 90_000 + 10_000 - 95_000 = 5_000
      expect(result[:mileage_remaining]).to eq(5_000)
    end

    it "returns positive days_remaining" do
      expect(result[:days_remaining]).to be > 0
    end
  end

  context "when mileage threshold is breached" do
    let!(:threshold) do
      create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
             mileage_interval: 4_000, time_interval_months: nil)
    end
    let!(:entry) do
      create(:service_log_entry, vehicle: vehicle, service_type: service_type,
             mileage_at_service: 90_000, serviced_on: 1.month.ago.to_date)
    end

    it "returns :due_soon" do
      # 90_000 + 4_000 - 95_000 = -1_000 (breached)
      expect(result[:status]).to eq(:due_soon)
    end

    it "returns negative mileage_remaining" do
      expect(result[:mileage_remaining]).to eq(-1_000)
    end

    it "returns nil days_remaining (no time threshold)" do
      expect(result[:days_remaining]).to be_nil
    end
  end

  context "when time threshold is breached" do
    let!(:threshold) do
      create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
             mileage_interval: nil, time_interval_months: 6)
    end
    let!(:entry) do
      create(:service_log_entry, vehicle: vehicle, service_type: service_type,
             mileage_at_service: 80_000, serviced_on: 8.months.ago.to_date)
    end

    it "returns :due_soon" do
      expect(result[:status]).to eq(:due_soon)
    end

    it "returns nil mileage_remaining (no mileage threshold)" do
      expect(result[:mileage_remaining]).to be_nil
    end

    it "returns negative days_remaining" do
      expect(result[:days_remaining]).to be < 0
    end
  end

  context "when only mileage threshold is configured" do
    let!(:threshold) do
      create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
             mileage_interval: 10_000, time_interval_months: nil)
    end
    let!(:entry) do
      create(:service_log_entry, vehicle: vehicle, service_type: service_type,
             mileage_at_service: 90_000, serviced_on: 1.month.ago.to_date)
    end

    it "returns nil for days_remaining" do
      expect(result[:days_remaining]).to be_nil
    end

    it "returns an integer mileage_remaining" do
      expect(result[:mileage_remaining]).to be_a(Integer)
    end
  end

  context "when only time threshold is configured" do
    let!(:threshold) do
      create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
             mileage_interval: nil, time_interval_months: 12)
    end
    let!(:entry) do
      create(:service_log_entry, vehicle: vehicle, service_type: service_type,
             mileage_at_service: 90_000, serviced_on: 1.month.ago.to_date)
    end

    it "returns nil for mileage_remaining" do
      expect(result[:mileage_remaining]).to be_nil
    end

    it "returns an integer days_remaining" do
      expect(result[:days_remaining]).to be_a(Integer)
    end
  end

  context "when threshold exists but no log entry" do
    let!(:threshold) do
      create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
             mileage_interval: 5_000, time_interval_months: 12)
    end

    it "returns :due_soon (no entry = base mileage 0, base date = now - interval)" do
      expect(result[:status]).to eq(:due_soon)
    end

    it "returns negative mileage_remaining (0 + 5_000 - 95_000)" do
      expect(result[:mileage_remaining]).to eq(-90_000)
    end

    it "returns ~0 days_remaining (base_date = now - 12.months, due = now)" do
      # base_date = Date.current - 12.months, due = base_date + 12.months = Date.current
      expect(result[:days_remaining]).to be_between(-1, 0)
    end
  end
end
