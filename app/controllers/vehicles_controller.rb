class VehiclesController < ApplicationController
  before_action :set_vehicle, only: [ :edit, :update, :destroy ]

  def index
    @vehicles = current_user.vehicles.order(created_at: :desc)
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

  private

  def set_vehicle
    @vehicle = current_user.vehicles.find(params[:id])
  end

  def vehicle_params
    params.require(:vehicle).permit(:make, :model, :year, :current_mileage)
  end
end
