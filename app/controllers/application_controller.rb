class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern


  rescue_from ActiveModel::ForbiddenAttributesError,
            with: :rescue_forbidden_attributes_error

  def rescue_forbidden_attributes_error
    head 422
  end
end
