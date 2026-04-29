class DashboardController < ApplicationController
  def index
    vehicles = current_user.vehicles
                           .includes(:service_log_entries, :reminder_thresholds)
                           .order(created_at: :desc)
    service_types = ServiceType.order(:name)

    @vehicle_summaries = vehicles.map do |vehicle|
      statuses = service_types.map do |st|
        DueSoonCalculator.call(vehicle: vehicle, service_type: st)[:status]
      end
      overall = if statuses.include?(:due_soon) then :due_soon
                elsif statuses.include?(:ok)     then :ok
                else                                  :unconfigured
                end
      { vehicle: vehicle, status: overall }
    end
  end
end
