# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "repos/:owner/:repo/tickets", to: "tickets#index"
      post "repos/:owner/:repo/tickets", to: "tickets#create"
      get "repos/:owner/:repo/tickets/stored", to: "tickets#stored"
      post "repos/:owner/:repo/sync", to: "tickets#sync"
      get "repos/:owner/:repo/tickets/:number", to: "tickets#show"
      get "repos/:owner/:repo/tickets/:number/analyze", to: "tickets#analyze"
      get "repos/:owner/:repo/analyze", to: "tickets#analyze_repo"
    end
  end

  get "up", to: proc { [200, {}, ["OK"]] }
end
