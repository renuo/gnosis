# frozen_string_literal: true

class WebhooksController < ApplicationController
  protect_from_forgery except: %i[github_webhook_catcher semaphore_webhook_catcher]

  def github_webhook_catcher
    unless verify_signature(request.body.read, request.env['HTTP_X_HUB_SIGNATURE_256'],
                            ENV.fetch('GITHUB_WEBHOOK_SECRET', nil))
      return render json: {status: 403}, status: :forbidden
    end

    WebhookHandler.handle_github(params)

    render json: {status: :ok}
  end

  def semaphore_webhook_catcher
    unless verify_signature(request.body.read, "sha256=#{request.headers['X-Semaphore-Signature-256']}",
                            ENV.fetch('SEMAPHORE_WEBHOOK_SECRET', nil))
      return render json: {status: 403}, status: :forbidden
    end

    WebhookHandler.handle_semaphore(params)

    render json: {status: :ok}
  end

  def check_if_login_required
    false # No login required as this uses the "verify_signature" for validation
  end

  private

  def verify_signature(payload_body, recieved_signature, secret)
    signature = "sha256=#{OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret, payload_body)}"
    Rack::Utils.secure_compare(signature, recieved_signature)
  end
end
