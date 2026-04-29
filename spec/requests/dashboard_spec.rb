require 'rails_helper'

RSpec.describe "Dashboard", type: :request do
  let(:user) { create(:user) }

  describe "GET /" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated with no vehicles" do
      before { sign_in user }

      it "returns 200 with empty state" do
        get root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Add your first vehicle")
      end
    end

    context "when authenticated with vehicles" do
      let(:vehicle) { create(:vehicle, user: user, make: "Honda", model: "Civic", year: 2020, current_mileage: 50_000) }
      let(:service_type) { create(:service_type) }

      before do
        sign_in user
        vehicle
      end

      it "lists the user's vehicles" do
        get root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Honda")
        expect(response.body).to include("Civic")
      end

      it "does not list other users' vehicles" do
        create(:vehicle, user: create(:user), make: "Ford", model: "Focus", year: 2018, current_mileage: 30_000)
        get root_path
        expect(response.body).not_to include("Ford")
      end

      it "delegates due-soon calculation to DueSoonCalculator" do
        create(:reminder_threshold, vehicle: vehicle, service_type: service_type, mileage_interval: 10_000)
        expect(DueSoonCalculator).to receive(:call)
          .with(vehicle: vehicle, service_type: anything)
          .and_call_original
          .at_least(:once)
        get root_path
      end

      it "shows due-soon badge when a threshold is breached" do
        create(:reminder_threshold, vehicle: vehicle, service_type: service_type, mileage_interval: 1_000)
        create(:service_log_entry, vehicle: vehicle, service_type: service_type,
               mileage_at_service: 1_000, serviced_on: 2.years.ago)
        get root_path
        expect(response.body).to include("Due Soon")
      end

      it "shows ok badge when thresholds are configured and not breached" do
        create(:reminder_threshold, vehicle: vehicle, service_type: service_type, mileage_interval: 100_000)
        create(:service_log_entry, vehicle: vehicle, service_type: service_type,
               mileage_at_service: 49_000, serviced_on: 1.month.ago)
        get root_path
        expect(response.body).to include("OK")
      end

      it "includes a link to each vehicle's detail page" do
        get root_path
        expect(response.body).to include(%(href="#{vehicle_path(vehicle)}"))
      end

      it "shows not configured badge when no thresholds are set" do
        service_type # force creation so DueSoonCalculator iterates it and returns :unconfigured
        get root_path
        expect(response.body).to include("Not configured")
      end
    end
  end
end
