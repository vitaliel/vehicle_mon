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
end
