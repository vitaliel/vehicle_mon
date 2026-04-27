require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  describe "GET /users/sign_in" do
    it "returns http success" do
      get new_user_session_path
      expect(response).to have_http_status(:ok)
    end

    it "renders email and password fields with labels" do
      get new_user_session_path
      expect(response.body).to include('type="email"')
      expect(response.body).to include('type="password"')
      expect(response.body).to match(/label.*for=["']user_email["']|label.*Email/i)
      expect(response.body).to match(/label.*for=["']user_password["']|label.*Password/i)
    end
  end

  describe "POST /users/sign_in" do
    let(:user) { create(:user) }

    context "with valid credentials" do
      it "signs in and redirects to root with a notice" do
        post user_session_path, params: {
          user: { email: user.email, password: user.password }
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to match(/signed in/i)
      end
    end

    context "with invalid credentials" do
      it "shows flash alert and stays on sign-in page" do
        post user_session_path, params: {
          user: { email: user.email, password: "wrongpassword" }
        }

        expect(response).to have_http_status(:ok).or have_http_status(:unprocessable_content)
        expect(response.body).to match(/invalid.*email.*password|invalid.*credentials/i)
      end
    end
  end

  describe "DELETE /users/sign_out" do
    let(:user) { create(:user) }

    it "invalidates the session and redirects to sign-in" do
      sign_in user
      delete destroy_user_session_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "prevents access to protected routes after sign-out" do
      sign_in user
      delete destroy_user_session_path

      get root_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "protected route enforcement" do
    it "redirects unauthenticated users to sign-in" do
      get root_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
