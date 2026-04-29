require 'rails_helper'

RSpec.describe "ReminderThresholds", type: :request do
  let(:user)         { create(:user) }
  let(:other_user)   { create(:user) }
  let(:vehicle)      { create(:vehicle, user: user) }
  let(:service_type) { create(:service_type) }

  # ── GET index ──────────────────────────────────────────────────────────────

  describe "GET /vehicles/:vehicle_id/reminder_thresholds" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        get vehicle_reminder_thresholds_path(vehicle)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated with own vehicle" do
      before { sign_in user }

      it "returns 200" do
        get vehicle_reminder_thresholds_path(vehicle)
        expect(response).to have_http_status(:ok)
      end

      it "shows 'Not configured' for unconfigured service types" do
        service_type # ensure at least one exists
        get vehicle_reminder_thresholds_path(vehicle)
        expect(response.body).to include("Not configured")
      end

      it "shows mileage interval when threshold is configured" do
        create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
               mileage_interval: 10_000, time_interval_months: nil)
        get vehicle_reminder_thresholds_path(vehicle)
        expect(response.body).to include("10,000 km")
      end

      it "shows time interval when threshold is configured" do
        create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
               mileage_interval: nil, time_interval_months: 6)
        get vehicle_reminder_thresholds_path(vehicle)
        expect(response.body).to include("6 months")
      end
    end

    context "when accessing another user's vehicle" do
      before { sign_in user }

      it "redirects to root with alert" do
        other_vehicle = create(:vehicle, user: other_user)
        get vehicle_reminder_thresholds_path(other_vehicle)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  # ── GET new ────────────────────────────────────────────────────────────────

  describe "GET /vehicles/:vehicle_id/reminder_thresholds/new" do
    context "when unauthenticated" do
      it "redirects to sign-in" do
        get new_vehicle_reminder_threshold_path(vehicle)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated with own vehicle" do
      before { sign_in user }

      it "returns 200" do
        get new_vehicle_reminder_threshold_path(vehicle)
        expect(response).to have_http_status(:ok)
      end

      it "pre-selects service_type_id when provided as param" do
        get new_vehicle_reminder_threshold_path(vehicle, service_type_id: service_type.id)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when accessing another user's vehicle" do
      before { sign_in user }

      it "redirects to root" do
        other_vehicle = create(:vehicle, user: other_user)
        get new_vehicle_reminder_threshold_path(other_vehicle)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  # ── POST create ────────────────────────────────────────────────────────────

  describe "POST /vehicles/:vehicle_id/reminder_thresholds" do
    before { sign_in user }

    context "with mileage interval only" do
      it "creates a threshold and redirects to index with notice" do
        expect {
          post vehicle_reminder_thresholds_path(vehicle),
               params: { reminder_threshold: { service_type_id: service_type.id,
                                               mileage_interval: 10_000,
                                               time_interval_months: "" } }
        }.to change(ReminderThreshold, :count).by(1)
        expect(response).to redirect_to(vehicle_path(vehicle))
        follow_redirect!
        expect(response.body).to include("Reminder threshold saved")
      end
    end

    context "with both mileage and time intervals" do
      it "creates a threshold" do
        expect {
          post vehicle_reminder_thresholds_path(vehicle),
               params: { reminder_threshold: { service_type_id: service_type.id,
                                               mileage_interval: 10_000,
                                               time_interval_months: 12 } }
        }.to change(ReminderThreshold, :count).by(1)
        expect(response).to redirect_to(vehicle_path(vehicle))
      end
    end

    context "when threshold already exists for the service type" do
      it "updates existing threshold instead of creating a duplicate row" do
        existing = create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
                          mileage_interval: 10_000, time_interval_months: 12)

        expect {
          post vehicle_reminder_thresholds_path(vehicle),
               params: { reminder_threshold: { service_type_id: service_type.id,
                                               mileage_interval: 8_000,
                                               time_interval_months: 6 } }
        }.not_to change(ReminderThreshold, :count)

        expect(response).to redirect_to(vehicle_path(vehicle))
        expect(existing.reload.mileage_interval).to eq(8_000)
        expect(existing.time_interval_months).to eq(6)
      end
    end

    context "with both intervals blank" do
      it "does not create a threshold and redirects gracefully" do
        expect {
          post vehicle_reminder_thresholds_path(vehicle),
               params: { reminder_threshold: { service_type_id: service_type.id,
                                               mileage_interval: "",
                                               time_interval_months: "" } }
        }.not_to change(ReminderThreshold, :count)
        expect(response).to redirect_to(vehicle_reminder_thresholds_path(vehicle))
      end
    end

    context "when accessing another user's vehicle" do
      it "redirects to root" do
        other_vehicle = create(:vehicle, user: other_user)
        post vehicle_reminder_thresholds_path(other_vehicle),
             params: { reminder_threshold: { service_type_id: service_type.id,
                                             mileage_interval: 10_000 } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  # ── GET edit ───────────────────────────────────────────────────────────────

  describe "GET /vehicles/:vehicle_id/reminder_thresholds/:id/edit" do
    let!(:threshold) { create(:reminder_threshold, vehicle: vehicle, service_type: service_type) }

    before { sign_in user }

    it "returns 200 for own threshold" do
      get edit_vehicle_reminder_threshold_path(vehicle, threshold)
      expect(response).to have_http_status(:ok)
    end

    it "redirects to root for another user's vehicle" do
      other_vehicle = create(:vehicle, user: other_user)
      other_threshold = create(:reminder_threshold, vehicle: other_vehicle, service_type: service_type)
      sign_in user
      get edit_vehicle_reminder_threshold_path(other_vehicle, other_threshold)
      expect(response).to redirect_to(root_path)
    end
  end

  # ── PATCH update ───────────────────────────────────────────────────────────

  describe "PATCH /vehicles/:vehicle_id/reminder_thresholds/:id" do
    let!(:threshold) do
      create(:reminder_threshold, vehicle: vehicle, service_type: service_type,
             mileage_interval: 10_000, time_interval_months: 12)
    end

    before { sign_in user }

    context "with valid params" do
      it "updates threshold and redirects to index with notice" do
        patch vehicle_reminder_threshold_path(vehicle, threshold),
              params: { reminder_threshold: { mileage_interval: 8_000,
                                              time_interval_months: 6 } }
        expect(response).to redirect_to(vehicle_path(vehicle))
        follow_redirect!
        expect(response.body).to include("Reminder threshold updated")
        expect(threshold.reload.mileage_interval).to eq(8_000)
      end

      it "ignores crafted service_type_id changes" do
        other_service_type = create(:service_type)

        patch vehicle_reminder_threshold_path(vehicle, threshold),
              params: { reminder_threshold: { service_type_id: other_service_type.id,
                                              mileage_interval: 8_000,
                                              time_interval_months: 6 } }

        expect(response).to redirect_to(vehicle_path(vehicle))
        expect(threshold.reload.service_type_id).to eq(service_type.id)
      end
    end

    context "with both intervals blank (clearing threshold)" do
      it "destroys the threshold and redirects with notice" do
        expect {
          patch vehicle_reminder_threshold_path(vehicle, threshold),
                params: { reminder_threshold: { mileage_interval: "",
                                                time_interval_months: "" } }
        }.to change(ReminderThreshold, :count).by(-1)
        expect(response).to redirect_to(vehicle_path(vehicle))
        follow_redirect!
        expect(response.body).to include("Threshold removed")
      end
    end

    context "when accessing another user's vehicle" do
      it "redirects to root" do
        other_vehicle   = create(:vehicle, user: other_user)
        other_threshold = create(:reminder_threshold, vehicle: other_vehicle,
                                 service_type: create(:service_type))
        patch vehicle_reminder_threshold_path(other_vehicle, other_threshold),
              params: { reminder_threshold: { mileage_interval: 5_000 } }
        expect(response).to redirect_to(root_path)
      end
    end

    context "recalculates due-soon status on vehicle show after threshold update" do
      it "shows due-soon badge when mileage interval is lowered below current gap" do
        create(:service_log_entry, vehicle: vehicle, service_type: service_type,
               mileage_at_service: 40_000, serviced_on: 6.months.ago)
        # vehicle.current_mileage: 45_000 (default)
        # threshold.mileage_interval: 10_000 → 40_000 + 10_000 - 45_000 = 5_000 > 0 → :ok before update
        expect(DueSoonCalculator).to receive(:call)
          .with(vehicle: vehicle, service_type: service_type)
          .and_call_original
          .at_least(:once)

        # Lower interval to 3_000 → 40_000 + 3_000 - 45_000 = -2_000 ≤ 0 → :due_soon after update
        patch vehicle_reminder_threshold_path(vehicle, threshold),
              params: { reminder_threshold: { mileage_interval: 3_000,
                                              time_interval_months: "" } }
        expect(response).to redirect_to(vehicle_path(vehicle))
        follow_redirect!
        expect(response.body).to include(service_type.name)
        expect(response.body).to include("Due Soon")
      end
    end
  end

  # ── DELETE destroy ─────────────────────────────────────────────────────────

  describe "DELETE /vehicles/:vehicle_id/reminder_thresholds/:id" do
    let!(:threshold) { create(:reminder_threshold, vehicle: vehicle, service_type: service_type) }

    before { sign_in user }

    it "destroys the threshold and redirects to index with notice" do
      expect {
        delete vehicle_reminder_threshold_path(vehicle, threshold)
      }.to change(ReminderThreshold, :count).by(-1)
      expect(response).to redirect_to(vehicle_reminder_thresholds_path(vehicle))
      follow_redirect!
      expect(response.body).to include("Reminder threshold removed")
    end

    it "redirects to root when trying to destroy another user's threshold" do
      other_vehicle   = create(:vehicle, user: other_user)
      other_threshold = create(:reminder_threshold, vehicle: other_vehicle,
                               service_type: create(:service_type))
      delete vehicle_reminder_threshold_path(other_vehicle, other_threshold)
      expect(response).to redirect_to(root_path)
    end
  end
end
