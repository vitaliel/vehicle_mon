require 'rails_helper'

RSpec.describe "Vehicles", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /vehicles" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        get vehicles_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated with no vehicles" do
      before { sign_in user }

      it "returns 200 with empty state" do
        get vehicles_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Add Vehicle")
      end
    end

    context "when authenticated with vehicles" do
      before do
        sign_in user
        create(:vehicle, user: user, make: "Honda", model: "Civic", year: 2019, current_mileage: 60_000)
      end

      it "shows the user's vehicles" do
        get vehicles_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Honda")
        expect(response.body).to include("Civic")
      end

      it "does not show other users' vehicles" do
        create(:vehicle, user: other_user, make: "Ford", model: "Focus", year: 2018, current_mileage: 30_000)
        get vehicles_path
        expect(response.body).not_to include("Ford")
        expect(response.body).not_to include("Focus")
      end
    end
  end

  describe "GET /vehicles/new" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        get new_vehicle_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns 200" do
        get new_vehicle_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /vehicles" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        post vehicles_path, params: { vehicle: { make: "Toyota", model: "Camry", year: 2020, current_mileage: 45_000 } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated with valid params" do
      before { sign_in user }

      it "creates vehicle, redirects to vehicles_path, and sets flash[:notice]" do
        expect {
          post vehicles_path, params: { vehicle: { make: "Toyota", model: "Camry", year: 2020, current_mileage: 45_000 } }
        }.to change(Vehicle, :count).by(1)

        expect(response).to redirect_to(vehicles_path)
        follow_redirect!
        expect(response.body).to include("Vehicle added successfully")
      end

      it "scopes the vehicle to the current user" do
        post vehicles_path, params: { vehicle: { make: "Toyota", model: "Camry", year: 2020, current_mileage: 45_000 } }
        expect(Vehicle.last.user).to eq(user)
      end
    end

    context "when authenticated with invalid params (missing make)" do
      before { sign_in user }

      it "re-renders new with status 422" do
        post vehicles_path, params: { vehicle: { make: "", model: "Camry", year: 2020, current_mileage: 45_000 } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("can&#39;t be blank")
      end
    end
  end

  describe "GET /vehicles/:id/edit" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        vehicle = create(:vehicle)
        get edit_vehicle_path(vehicle)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns 200 for own vehicle" do
        vehicle = create(:vehicle, user: user)
        get edit_vehicle_path(vehicle)
        expect(response).to have_http_status(:ok)
      end

      it "redirects to root for another user's vehicle" do
        other_vehicle = create(:vehicle, user: other_user)
        get edit_vehicle_path(other_vehicle)
        expect(response).to redirect_to(root_path)
      end

      it "redirects to root for a non-existent vehicle" do
        get edit_vehicle_path(-1)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /vehicles/:id" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        vehicle = create(:vehicle)
        patch vehicle_path(vehicle), params: { vehicle: { make: "Honda" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      let(:vehicle) { create(:vehicle, user: user, make: "Toyota", model: "Camry", year: 2020, current_mileage: 45_000) }

      before { sign_in user }

      it "updates vehicle and redirects to vehicles_path with flash[:notice]" do
        patch vehicle_path(vehicle), params: { vehicle: { make: "Honda" } }
        expect(response).to redirect_to(vehicles_path)
        follow_redirect!
        expect(response.body).to include("Vehicle updated successfully")
        expect(vehicle.reload.make).to eq("Honda")
      end

      it "re-renders edit with status 422 on invalid params" do
        patch vehicle_path(vehicle), params: { vehicle: { make: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("can&#39;t be blank")
      end

      it "redirects to root for another user's vehicle" do
        other_vehicle = create(:vehicle, user: other_user)
        original_make = other_vehicle.make
        patch vehicle_path(other_vehicle), params: { vehicle: { make: "Honda" } }
        expect(response).to redirect_to(root_path)
        expect(other_vehicle.reload.make).to eq(original_make)
      end

      it "redirects to root for a non-existent vehicle" do
        patch vehicle_path(-1), params: { vehicle: { make: "Honda" } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /vehicles/:id" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        vehicle = create(:vehicle)
        delete vehicle_path(vehicle)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      let(:vehicle) { create(:vehicle, user: user) }

      before { sign_in user }

      it "deletes own vehicle and cascades associated records" do
        vehicle
        create(:service_log_entry, vehicle: vehicle)
        create(:reminder_threshold, vehicle: vehicle)

        expect {
          delete vehicle_path(vehicle)
        }.to change(Vehicle, :count).by(-1)
          .and change(ServiceLogEntry, :count).by(-1)
          .and change(ReminderThreshold, :count).by(-1)
        expect(response).to redirect_to(vehicles_path)
        follow_redirect!
        expect(response.body).to include("deleted successfully")
      end

      it "redirects to root for another user's vehicle without deleting it" do
        other_vehicle = create(:vehicle, user: other_user)
        expect {
          delete vehicle_path(other_vehicle)
        }.not_to change(Vehicle, :count)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /vehicles/:id" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        vehicle = create(:vehicle)
        get vehicle_path(vehicle)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "shows own vehicle detail page" do
        vehicle = create(:vehicle, user: user)
        get vehicle_path(vehicle)
        expect(response).to have_http_status(:ok)
      end

      it "includes a link to service history on vehicle detail page" do
        vehicle = create(:vehicle, user: user)
        get vehicle_path(vehicle)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("View Service History")
        expect(response.body).to include(%(href="#{vehicle_service_log_entries_path(vehicle)}"))
      end

      it "redirects to root with flash[:alert] for another user's vehicle" do
        other_vehicle = create(:vehicle, user: other_user)
        get vehicle_path(other_vehicle)
        expect(response).to redirect_to(root_path)
        follow_redirect!
        flash_alert = Nokogiri::HTML(response.body).at_css(".alert.alert-danger")
        expect(flash_alert).to be_present
        expect(flash_alert.text).to include("Record not found.")
      end

      context "due-soon section" do
        let(:vehicle) { create(:vehicle, user: user, current_mileage: 60_000) }
        let(:service_type) { create(:service_type) }

        it "shows OK badge when threshold is configured and not breached" do
          create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
                 mileage_interval: 15_000, time_interval_months: nil)
          create(:service_log_entry, vehicle: vehicle, service_type: service_type,
                 mileage_at_service: 50_000, serviced_on: 1.month.ago)
          get vehicle_path(vehicle)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include(service_type.name)
          expect(response.body).to include("OK")
        end

        it "shows Due Soon badge when threshold is breached" do
          create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
                 mileage_interval: 5_000, time_interval_months: nil)
          create(:service_log_entry, vehicle: vehicle, service_type: service_type,
                 mileage_at_service: 50_000, serviced_on: 1.month.ago)
          get vehicle_path(vehicle)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include(service_type.name)
          expect(response.body).to include("Due Soon")
        end

        it "shows Not configured for service types with no threshold" do
          _ = service_type # force creation before the request so it appears in ServiceType.order(:name)
          get vehicle_path(vehicle)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include(service_type.name)
          expect(response.body).to include("Not configured")
        end

        it "shows all seeded service types in the due-soon section" do
          service_types = [
            create(:service_type, name: "Engine Oil"),
            create(:service_type, name: "Spark Plugs"),
            create(:service_type, name: "Air Filter"),
            create(:service_type, name: "Brake Pads"),
            create(:service_type, name: "Transmission Fluid"),
            create(:service_type, name: "Tires")
          ]
          get vehicle_path(vehicle)
          service_types.each do |st|
            expect(response.body).to include(st.name)
          end
        end

        it "delegates due-soon calculation to DueSoonCalculator (never inline logic)" do
          create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
                 mileage_interval: 15_000, time_interval_months: nil)
          expect(DueSoonCalculator).to receive(:call).with(vehicle: vehicle, service_type: service_type).and_call_original
          get vehicle_path(vehicle)
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "PATCH /vehicles/:id/update_mileage" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        vehicle = create(:vehicle)
        patch update_mileage_vehicle_path(vehicle), params: { vehicle: { current_mileage: 60_000 } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      let(:vehicle) { create(:vehicle, user: user, current_mileage: 50_000) }

      before { sign_in user }

      it "updates mileage and redirects to vehicle_path with flash[:notice]" do
        patch update_mileage_vehicle_path(vehicle), params: { vehicle: { current_mileage: 60_000 } }
        expect(vehicle.reload.current_mileage).to eq(60_000)
        expect(response).to redirect_to(vehicle_path(vehicle))
        follow_redirect!
        expect(response.body).to include("Mileage updated successfully")
      end

      it "rejects a negative mileage and returns 422" do
        patch update_mileage_vehicle_path(vehicle), params: { vehicle: { current_mileage: -1 } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(vehicle.reload.current_mileage).to eq(50_000)
      end

      it "rejects a non-numeric mileage and returns 422" do
        patch update_mileage_vehicle_path(vehicle), params: { vehicle: { current_mileage: "abc" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(vehicle.reload.current_mileage).to eq(50_000)
      end

      it "redirects to root for another user's vehicle" do
        other_vehicle = create(:vehicle, user: other_user)
        patch update_mileage_vehicle_path(other_vehicle), params: { vehicle: { current_mileage: 60_000 } }
        expect(response).to redirect_to(root_path)
      end

      context "recalculates due-soon for multiple service types after mileage update" do
        let(:service_type_1) { create(:service_type) }
        let(:service_type_2) { create(:service_type) }

        it "shows due-soon badges for both service types on vehicle show" do
          create(:reminder_threshold, vehicle: vehicle, service_type: service_type_1,
                 mileage_interval: 15_000, time_interval_months: nil)
          create(:reminder_threshold, vehicle: vehicle, service_type: service_type_2,
                 mileage_interval: 15_000, time_interval_months: nil)
          create(:service_log_entry, vehicle: vehicle, service_type: service_type_1,
                 mileage_at_service: 40_000, serviced_on: 6.months.ago)
          create(:service_log_entry, vehicle: vehicle, service_type: service_type_2,
                 mileage_at_service: 40_000, serviced_on: 6.months.ago)
          # vehicle.current_mileage: 50_000; 40_000 + 15_000 - 50_000 = 5_000 > 0 → :ok for both
          # after update to 60_000: 40_000 + 15_000 - 60_000 = -5_000 ≤ 0 → :due_soon for both

          get vehicle_path(vehicle)
          expect(response.body).not_to include("Due Soon")

          expect(DueSoonCalculator).to receive(:call)
            .with(vehicle: vehicle, service_type: service_type_1)
            .and_call_original
            .at_least(:once)
          expect(DueSoonCalculator).to receive(:call)
            .with(vehicle: vehicle, service_type: service_type_2)
            .and_call_original
            .at_least(:once)

          patch update_mileage_vehicle_path(vehicle), params: { vehicle: { current_mileage: 60_000 } }
          expect(response).to redirect_to(vehicle_path(vehicle))
          follow_redirect!
          expect(response.body).to include(service_type_1.name)
          expect(response.body).to include(service_type_2.name)
          expect(response.body).to include("Due Soon")
        end
      end
    end
  end
end
