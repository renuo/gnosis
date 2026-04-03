# frozen_string_literal: true

# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

scope 'gnosis' do
  resources :example, only: [:index]

  post 'github_webhook', to: 'gnosis/webhooks#github_webhook_catcher'
  post 'semaphore_webhook', to: 'gnosis/webhooks#semaphore_webhook_catcher'
  get 'sync_pull_requests', to: 'gnosis/sync#sync_pull_requests'
end

resources :projects do
  get 'gnosis/deployments', to: 'gnosis/deployments#index', as: :gnosis_deployments
end
