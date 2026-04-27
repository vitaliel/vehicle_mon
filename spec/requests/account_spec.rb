require 'rails_helper'

RSpec.describe "Account", type: :request do
  let(:user) { create(:user) }

  describe "GET /users/edit" do
    context "when not authenticated" do
      it "redirects to sign-in" do
        get edit_user_registration_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns http success" do
        get edit_user_registration_path
        expect(response).to have_http_status(:ok)
      end

      it "renders form pre-filled with current email" do
        get edit_user_registration_path
        expect(response.body).to include(user.email)
      end

      it "renders labeled email, current password, new password, and confirmation fields" do
        get edit_user_registration_path
        expect(response.body).to include('type="email"')
        expect(response.body).to include('type="password"')
        expect(response.body).to match(/label.*Email/i)
        expect(response.body).to match(/label.*Password/i)
        expect(response.body).to match(/current.password/i)
      end

      it "shows account settings link in the nav" do
        get root_path
        expect(response.body).to match(/Account Settings/i)
      end
    end
  end

  describe "PATCH /users (email update)" do
    before { sign_in user }

    context "with a valid new email and correct current password" do
      it "updates the email and redirects with a notice" do
        patch user_registration_path, params: {
          user: {
            email: "newemail@example.com",
            current_password: "password123"
          }
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to match(/updated/i)
        expect(user.reload.email).to eq("newemail@example.com")
      end
    end
  end

  describe "PATCH /users (password update)" do
    before { sign_in user }

    context "with a valid new password and correct current password" do
      it "updates the password, keeps user signed in, and redirects with a notice" do
        patch user_registration_path, params: {
          user: {
            password: "newpassword456",
            password_confirmation: "newpassword456",
            current_password: "password123"
          }
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to match(/updated/i)

        # User should still be signed in (root is protected)
        expect(response).to have_http_status(:ok)
        get edit_user_registration_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "with an incorrect current password" do
      it "rejects the update and re-renders with a validation error" do
        patch user_registration_path, params: {
          user: {
            password: "newpassword456",
            password_confirmation: "newpassword456",
            current_password: "wrongpassword"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to match(/current password/i)

        # Password should not have changed
        user.reload
        expect(user.valid_password?("password123")).to be true
        expect(user.valid_password?("newpassword456")).to be false
      end
    end
  end
end
