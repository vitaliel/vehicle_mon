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
        expect(response).to redirect_to(vehicle_path(vehicle))
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

    context "recalculates due-soon status on vehicle show after create" do
      let(:vehicle) { create(:vehicle, user: user, current_mileage: 60_000) }

      before { sign_in user }

      it "redirects to vehicle show where due-soon reflects the new log entry" do
        create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
               mileage_interval: 5_000, time_interval_months: nil)
        create(:service_log_entry, vehicle: vehicle, service_type: service_type,
               mileage_at_service: 50_000, serviced_on: 6.months.ago)
        # Before: 50_000 + 5_000 - 60_000 = -5_000 ≤ 0 → :due_soon
        # After logging at 60_000: 60_000 + 5_000 - 60_000 = 5_000 > 0 → :ok
        expect(DueSoonCalculator).to receive(:call)
          .with(vehicle: vehicle, service_type: service_type)
          .and_call_original
          .at_least(:once)

        post vehicle_service_log_entries_path(vehicle),
             params: { service_log_entry: {
               service_type_id: service_type.id,
               serviced_on: Date.today,
               mileage_at_service: 60_000,
               service_center: "Test Center"
             } }
        expect(response).to redirect_to(vehicle_path(vehicle))
        follow_redirect!
        expect(response.body).to include(service_type.name)
      end
    end
  end

  describe "GET /vehicles/:vehicle_id/service_log_entries/:id/edit" do
    let(:entry) { create(:service_log_entry, vehicle: vehicle, service_type: service_type) }

    context "when unauthenticated" do
      it "redirects to sign-in" do
        get edit_vehicle_service_log_entry_path(vehicle, entry)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as owner" do
      before { sign_in user }

      it "returns 200 with pre-filled field values" do
        get edit_vehicle_service_log_entry_path(vehicle, entry)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(entry.service_center)
        expect(response.body).to include(entry.mileage_at_service.to_s)
        expect(response.body).to include(entry.serviced_on.to_s)
      end

      it "redirects to root when accessing another user's entry" do
        other_vehicle = create(:vehicle, user: other_user)
        other_entry = create(:service_log_entry, vehicle: other_vehicle, service_type: service_type)
        get edit_vehicle_service_log_entry_path(other_vehicle, other_entry)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "PATCH /vehicles/:vehicle_id/service_log_entries/:id" do
    let(:entry) { create(:service_log_entry, vehicle: vehicle, service_type: service_type) }
    let(:valid_update) do
      {
        service_log_entry: {
          service_type_id: service_type.id,
          serviced_on: Date.today,
          mileage_at_service: 55_000,
          service_center: "Updated Center",
          parts_cost: 30.00,
          labour_cost: 60.00,
          notes: "Updated notes"
        }
      }
    end

    context "when unauthenticated" do
      it "redirects to sign-in" do
        patch vehicle_service_log_entry_path(vehicle, entry), params: valid_update
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated with valid params" do
      before { sign_in user }

      it "updates the entry and redirects to index with flash[:notice]" do
        patch vehicle_service_log_entry_path(vehicle, entry), params: valid_update
        expect(response).to redirect_to(vehicle_service_log_entries_path(vehicle))
        expect(flash[:notice]).to eq("Service entry updated successfully.")
        expect(entry.reload.service_center).to eq("Updated Center")
      end
    end

    context "when authenticated with invalid params (blank serviced_on)" do
      before { sign_in user }

      it "re-renders edit with status 422 and shows validation error" do
        patch vehicle_service_log_entry_path(vehicle, entry),
              params: { service_log_entry: { serviced_on: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("error_explanation")
      end
    end

    context "when accessing another user's entry (cross-user)" do
      before { sign_in user }

      it "redirects to root with flash[:alert]" do
        other_vehicle = create(:vehicle, user: other_user)
        other_entry = create(:service_log_entry, vehicle: other_vehicle, service_type: service_type)
        patch vehicle_service_log_entry_path(other_vehicle, other_entry), params: valid_update
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "DELETE /vehicles/:vehicle_id/service_log_entries/:id" do
    let(:entry) { create(:service_log_entry, vehicle: vehicle, service_type: service_type) }

    context "when unauthenticated" do
      it "redirects to sign-in" do
        delete vehicle_service_log_entry_path(vehicle, entry)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as owner" do
      before { sign_in user }

      it "destroys the entry and redirects to index with flash[:notice]" do
        entry # materialize before delete
        expect {
          delete vehicle_service_log_entry_path(vehicle, entry)
        }.to change(ServiceLogEntry, :count).by(-1)
        expect(response).to redirect_to(vehicle_service_log_entries_path(vehicle))
        expect(flash[:notice]).to eq("Service entry deleted successfully.")
      end

      it "redirects with flash[:alert] when deletion fails" do
        entry
        allow_any_instance_of(ServiceLogEntry).to receive(:destroy) do |record|
          record.errors.add(:base, "Cannot delete this service entry.")
          false
        end

        expect {
          delete vehicle_service_log_entry_path(vehicle, entry)
        }.not_to change(ServiceLogEntry, :count)
        expect(response).to redirect_to(vehicle_service_log_entries_path(vehicle))
        expect(flash[:alert]).to eq("Cannot delete this service entry.")
      end
    end

    context "when accessing another user's entry (cross-user)" do
      before { sign_in user }

      it "redirects to root with flash[:alert]" do
        other_vehicle = create(:vehicle, user: other_user)
        other_entry = create(:service_log_entry, vehicle: other_vehicle, service_type: service_type)
        delete vehicle_service_log_entry_path(other_vehicle, other_entry)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
