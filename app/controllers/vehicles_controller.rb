class VehiclesController < ApplicationController
  before_action :set_vehicle, only: [ :show, :edit, :update, :destroy, :update_mileage ]

  def index
    @vehicles = current_user.vehicles.order(created_at: :desc)
  end

  def show
    @vehicle = current_user.vehicles
                           .includes(:service_log_entries, :reminder_thresholds)
                           .find(params[:id])
    build_due_soon_data
  end

  def new
    @vehicle = current_user.vehicles.build
  end

  def create
    @vehicle = current_user.vehicles.build(vehicle_params)
    if @vehicle.save
      redirect_to vehicles_path, notice: "Vehicle added successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @vehicle.update(vehicle_params)
      redirect_to vehicles_path, notice: "Vehicle updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @vehicle.destroy
      redirect_to vehicles_path, notice: "Vehicle deleted successfully."
    else
      error_message = @vehicle.errors.full_messages.to_sentence
      redirect_to vehicles_path, alert: error_message.presence || "Vehicle could not be deleted."
    end
  end

  def update_mileage
    if @vehicle.update(mileage_params)
      redirect_to vehicle_path(@vehicle), notice: "Mileage updated successfully."
    else
      @vehicle = current_user.vehicles
                             .includes(:service_log_entries, :reminder_thresholds)
                             .find(params[:id])
      build_due_soon_data
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_vehicle
    @vehicle = current_user.vehicles.find(params[:id])
  end

  def build_due_soon_data
    @service_types = ServiceType.order(:name)
    @due_soon_statuses = @service_types.each_with_object({}) do |st, h|
      h[st] = DueSoonCalculator.call(vehicle: @vehicle, service_type: st)
    end
  end

  def vehicle_params
    params.require(:vehicle).permit(:make, :model, :year, :current_mileage)
  end

  def mileage_params
    params.require(:vehicle).permit(:current_mileage)
  end
end
