# frozen_string_literal: true

Rails.application.routes.draw do
  get "up", to: proc { [200, {}, ["ok"]] }

  namespace :api do
    namespace :v1 do
      # GitHub webhook: receive issue/comment events and sync to Supabase
      post "webhooks/github", to: "webhooks#github"

      scope "repos/:owner/:repo" do
        get "tickets", to: "tickets#index"
        post "tickets", to: "tickets#create"
        get "tickets/stored", to: "tickets#stored"
        post "sync", to: "tickets#sync"
        get "analyze", to: "tickets#analyze_repo"
        get "tickets/:number", to: "tickets#show"
        get "tickets/:number/analyze", to: "tickets#analyze"
      end
    end
  end
end
