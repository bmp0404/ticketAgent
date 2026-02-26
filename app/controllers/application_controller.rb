# frozen_string_literal: true

class ApplicationController < ActionController::API
  rescue_from Octokit::NotFound, with: :not_found
  rescue_from Octokit::Unauthorized, with: :unauthorized
  rescue_from Octokit::Forbidden, with: :forbidden

  private

  def not_found(exception)
    render json: { error: "Not found", message: exception.message }, status: :not_found
  end

  def unauthorized(exception)
    render json: { error: "Unauthorized", message: "Invalid or missing GitHub token" }, status: :unauthorized
  end

  def forbidden(exception)
    render json: { error: "Forbidden", message: exception.message }, status: :forbidden
  end
end
