# frozen_string_literal: true

class ApplicationController < ActionController::API
  rescue_from Octokit::NotFound do |e|
    render json: { error: "Not found", message: e.message }, status: :not_found
  end

  rescue_from Octokit::Unauthorized do |e|
    render json: { error: "Unauthorized", message: e.message }, status: :unauthorized
  end

  rescue_from Octokit::Forbidden do |e|
    render json: { error: "Forbidden", message: e.message }, status: :forbidden
  end
end
