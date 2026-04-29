class ReminderThresholdsController < ApplicationController
  before_action :set_vehicle
  before_action :set_threshold, only: [ :edit, :update, :destroy ]

  def index
    @service_types = ServiceType.order(:name)
    thresholds = @vehicle.reminder_thresholds.index_by(&:service_type_id)
    @thresholds_by_service_type = @service_types.each_with_object({}) do |st, h|
      h[st] = thresholds[st.id]
    end
  end

  def new
    @threshold = @vehicle.reminder_thresholds.build
    @threshold.service_type_id = params[:service_type_id]
    @service_types = ServiceType.order(:name)
  end

  def create
    if both_intervals_blank?(threshold_params)
      redirect_to vehicle_reminder_thresholds_path(@vehicle), notice: "No threshold configured."
      return
    end
    @threshold = @vehicle.reminder_thresholds.build(threshold_params)
    if @threshold.save
      redirect_to vehicle_reminder_thresholds_path(@vehicle), notice: "Reminder threshold saved."
    else
      @service_types = ServiceType.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @service_types = ServiceType.order(:name)
  end

  def update
    if both_intervals_blank?(threshold_params)
      @threshold.destroy
      redirect_to vehicle_reminder_thresholds_path(@vehicle), notice: "Threshold removed."
      return
    end
    if @threshold.update(threshold_params)
      redirect_to vehicle_reminder_thresholds_path(@vehicle), notice: "Reminder threshold updated."
    else
      @service_types = ServiceType.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @threshold.destroy
    redirect_to vehicle_reminder_thresholds_path(@vehicle), notice: "Reminder threshold removed."
  end

  private

  def set_vehicle
    @vehicle = current_user.vehicles.find(params[:vehicle_id])
  end

  def set_threshold
    @threshold = @vehicle.reminder_thresholds.find(params[:id])
  end

  def both_intervals_blank?(p)
    p[:mileage_interval].blank? && p[:time_interval_months].blank?
  end

  def threshold_params
    params.require(:reminder_threshold).permit(:service_type_id, :mileage_interval, :time_interval_months)
  end
end
