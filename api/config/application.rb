# frozen_string_literal: true

require_relative "boot"

require "active_record/railtie"
require "active_model/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

module GitHubTicketsApi
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins ENV.fetch("CORS_ORIGINS", "*")
        resource "/api/*", headers: :any, methods: %i[get post options]
      end
    end
  end
end
