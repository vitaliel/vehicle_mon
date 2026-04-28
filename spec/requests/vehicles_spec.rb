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
        ServiceLogEntry.create!(vehicle: vehicle)
        ReminderThreshold.create!(vehicle: vehicle)

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

      it "redirects to root for another user's vehicle" do
        other_vehicle = create(:vehicle, user: other_user)
        get vehicle_path(other_vehicle)
        expect(response).to redirect_to(root_path)
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
    end
  end
end
