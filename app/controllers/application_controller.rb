class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def handle_not_found
    redirect_to root_path, alert: "Record not found."
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end
end
