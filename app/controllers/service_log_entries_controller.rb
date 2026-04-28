class ServiceLogEntriesController < ApplicationController
  before_action :set_vehicle

  def index
    @entries = @vehicle.service_log_entries.includes(:service_type).order(serviced_on: :asc)
  end

  def new
    @entry = @vehicle.service_log_entries.build
    @service_types = ServiceType.order(:name)
  end

  def create
    @entry = @vehicle.service_log_entries.build(entry_params)
    if @entry.save
      redirect_to vehicle_service_log_entries_path(@vehicle), notice: "Service entry logged successfully."
    else
      @service_types = ServiceType.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_vehicle
    @vehicle = current_user.vehicles.find(params[:vehicle_id])
  end

  def entry_params
    params.require(:service_log_entry).permit(
      :service_type_id, :serviced_on, :mileage_at_service,
      :service_center, :parts_cost, :labour_cost, :notes
    )
  end
end
