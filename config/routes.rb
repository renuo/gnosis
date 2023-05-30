# frozen_string_literal: true

# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
resources :example, only: [:index]

post 'github_webhook', to: 'webhooks#github_webhook_catcher'
post 'semaphore_webhook', to: 'webhooks#semaphore_webhook_catcher'
