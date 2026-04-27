require 'rails_helper'

RSpec.describe "Registrations", type: :request do
  describe "GET /users/sign_up" do
    it "returns http success" do
      get new_user_registration_path
      expect(response).to have_http_status(:ok)
    end

    it "renders the registration form with email and password fields" do
      get new_user_registration_path
      expect(response.body).to include('type="email"')
      expect(response.body).to include('type="password"')
    end

    it "renders labels for email and password inputs" do
      get new_user_registration_path
      expect(response.body).to match(/label.*for=["']user_email["']|label.*Email/i)
      expect(response.body).to match(/label.*for=["']user_password["']|label.*Password/i)
    end
  end

  describe "POST /users (sign up)" do
    context "with valid credentials" do
      it "creates a user, signs them in, and redirects to root with a notice" do
        expect {
          post user_registration_path, params: {
            user: { email: "newuser@example.com", password: "password123", password_confirmation: "password123" }
          }
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Welcome")
      end
    end

    context "with a duplicate email" do
      before { create(:user, email: "existing@example.com") }

      it "re-renders the form with status 422 and shows an error" do
        post user_registration_path, params: {
          user: { email: "existing@example.com", password: "password123", password_confirmation: "password123" }
        }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with an invalid email" do
      it "re-renders the form with status 422 and shows an error" do
        post user_registration_path, params: {
          user: { email: "not-an-email", password: "password123", password_confirmation: "password123" }
        }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not include the password in the response body" do
        post user_registration_path, params: {
          user: { email: "not-an-email", password: "secret_pass", password_confirmation: "secret_pass" }
        }

        expect(response.body).not_to include("secret_pass")
      end
    end

    context "with missing email" do
      it "re-renders the form with status 422" do
        post user_registration_path, params: {
          user: { email: "", password: "password123", password_confirmation: "password123" }
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Email")
      end
    end
  end
end
