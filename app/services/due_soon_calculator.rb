class DueSoonCalculator
  def self.call(vehicle:, service_type:)
    new(vehicle: vehicle, service_type: service_type).call
  end

  def initialize(vehicle:, service_type:)
    @vehicle      = vehicle
    @service_type = service_type
  end

  def call
    threshold = ReminderThreshold.find_by(vehicle: @vehicle, service_type: @service_type)
    return unconfigured if threshold.nil?
    return unconfigured if threshold.mileage_interval.nil? && threshold.time_interval_months.nil?
    return unconfigured if threshold.mileage_interval && @vehicle.current_mileage.nil?

    last_entry = @vehicle.service_log_entries
                         .where(service_type: @service_type)
                         .order(serviced_on: :desc, id: :desc)
                         .first

    mileage_remaining = calculate_mileage_remaining(threshold, last_entry)
    days_remaining    = calculate_days_remaining(threshold, last_entry)

    status = determine_status(mileage_remaining, days_remaining)
    { status: status, mileage_remaining: mileage_remaining, days_remaining: days_remaining }
  end

  private

  def unconfigured
    { status: :unconfigured, mileage_remaining: nil, days_remaining: nil }
  end

  def calculate_mileage_remaining(threshold, last_entry)
    return nil unless threshold.mileage_interval

    base_mileage = last_entry&.mileage_at_service || 0
    base_mileage + threshold.mileage_interval - @vehicle.current_mileage
  end

  def calculate_days_remaining(threshold, last_entry)
    return nil unless threshold.time_interval_months

    base_date = last_entry&.serviced_on || (Date.current - threshold.time_interval_months.months)
    (base_date + threshold.time_interval_months.months - Date.current).to_i
  end

  def determine_status(mileage_remaining, days_remaining)
    breached = (mileage_remaining && mileage_remaining <= 0) ||
               (days_remaining && days_remaining <= 0)
    breached ? :due_soon : :ok
  end
end
