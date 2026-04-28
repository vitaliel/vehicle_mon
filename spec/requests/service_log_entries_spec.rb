require 'rails_helper'

RSpec.describe "ServiceLogEntries", type: :request do
  let(:user)       { create(:user) }
  let(:other_user) { create(:user) }
  let(:vehicle)    { create(:vehicle, user: user) }
  let(:service_type) { create(:service_type) }

  describe "GET /vehicles/:vehicle_id/service_log_entries" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        get vehicle_service_log_entries_path(vehicle)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns 200 with empty state when no entries" do
        get vehicle_service_log_entries_path(vehicle)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Log your first service entry")
      end

      it "lists existing entries in chronological order (oldest first)" do
        create(:service_log_entry, vehicle: vehicle, service_type: service_type,
               serviced_on: Date.new(2025, 1, 1), mileage_at_service: 90_000)
        create(:service_log_entry, vehicle: vehicle, service_type: service_type,
               serviced_on: Date.new(2025, 6, 1), mileage_at_service: 10_000)
        get vehicle_service_log_entries_path(vehicle)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(service_type.name)
        expect(response.body.index("01 Jan 2025")).to be < response.body.index("01 Jun 2025")
      end

      it "displays date formatted as DD Mon YYYY" do
        create(:service_log_entry, vehicle: vehicle, service_type: service_type,
               serviced_on: Date.new(2025, 4, 23), mileage_at_service: 45_000)
        get vehicle_service_log_entries_path(vehicle)
        expect(response.body).to include("23 Apr 2025")
      end

      it "displays mileage with delimiter and km suffix" do
        create(:service_log_entry, vehicle: vehicle, service_type: service_type,
               serviced_on: Date.today, mileage_at_service: 92_400)
        get vehicle_service_log_entries_path(vehicle)
        expect(response.body).to include("92,400 km")
      end

      it "displays costs formatted as currency" do
        create(:service_log_entry, vehicle: vehicle, service_type: service_type,
               serviced_on: Date.today, mileage_at_service: 10_000,
               parts_cost: 25.50, labour_cost: 80.00)
        get vehicle_service_log_entries_path(vehicle)
        expect(response.body).to include(ActionController::Base.helpers.number_to_currency(25.50))
        expect(response.body).to include(ActionController::Base.helpers.number_to_currency(80.00))
      end

      it "displays notes text" do
        create(:service_log_entry, vehicle: vehicle, service_type: service_type,
               serviced_on: Date.today, mileage_at_service: 10_000,
               notes: "Replaced cabin air filter")
        get vehicle_service_log_entries_path(vehicle)
        expect(response.body).to include("Replaced cabin air filter")
      end

      it "redirects to root when accessing another user's vehicle" do
        other_vehicle = create(:vehicle, user: other_user)
        get vehicle_service_log_entries_path(other_vehicle)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "GET /vehicles/:vehicle_id/service_log_entries/new" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        get new_vehicle_service_log_entry_path(vehicle)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns 200 with all service type labels" do
        create(:service_type, name: "Air Filter")
        get new_vehicle_service_log_entry_path(vehicle)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Service Type")
        expect(response.body).to include("Date of Service")
        expect(response.body).to include("Mileage at Service")
        expect(response.body).to include("Service Center Name")
        expect(response.body).to include("Parts Cost")
        expect(response.body).to include("Labour Cost")
        expect(response.body).to include("Notes")
        expect(response.body).to include("Air Filter")
      end

      it "redirects to root when accessing another user's vehicle" do
        other_vehicle = create(:vehicle, user: other_user)
        get new_vehicle_service_log_entry_path(other_vehicle)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "POST /vehicles/:vehicle_id/service_log_entries" do
    let(:valid_params) do
      {
        service_log_entry: {
          service_type_id: service_type.id,
          serviced_on: Date.today,
          mileage_at_service: 50_000,
          service_center: "Quick Lube",
          parts_cost: 25.00,
          labour_cost: 50.00,
          notes: "Changed oil"
        }
      }
    end

    context "when unauthenticated" do
      it "redirects to sign-in" do
        post vehicle_service_log_entries_path(vehicle), params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated with valid params" do
      before { sign_in user }

      it "creates a service log entry and redirects with flash[:notice]" do
        expect {
          post vehicle_service_log_entries_path(vehicle), params: valid_params
        }.to change(ServiceLogEntry, :count).by(1)
        expect(response).to redirect_to(vehicle_service_log_entries_path(vehicle))
        expect(flash[:notice]).to eq("Service entry logged successfully.")
      end

      it "scopes entry to the correct vehicle" do
        post vehicle_service_log_entries_path(vehicle), params: valid_params
        expect(ServiceLogEntry.last.vehicle).to eq(vehicle)
      end

      it "completes create in under 500ms" do
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        post vehicle_service_log_entries_path(vehicle), params: valid_params
        elapsed_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000

        expect(elapsed_ms).to be < 500
      end
    end

    context "when authenticated with missing required field (date)" do
      before { sign_in user }

      it "re-renders new with status 422" do
        params = valid_params.deep_merge(service_log_entry: { serviced_on: "" })
        post vehicle_service_log_entries_path(vehicle), params: params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when authenticated with missing required field (mileage)" do
      before { sign_in user }

      it "re-renders new with status 422" do
        params = valid_params.deep_merge(service_log_entry: { mileage_at_service: "" })
        post vehicle_service_log_entries_path(vehicle), params: params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when accessing another user's vehicle (cross-user)" do
      before { sign_in user }

      it "redirects to root with flash[:alert]" do
        other_vehicle = create(:vehicle, user: other_user)
        post vehicle_service_log_entries_path(other_vehicle), params: valid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
