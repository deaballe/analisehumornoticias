require "sidekiq/web"
require "sidekiq/cron/web"

if Rails.env.production?
  Sidekiq::Web.use Rack::Auth::Basic, "Sidekiq" do |username, password|
    expected_user = ENV.fetch("SIDEKIQ_WEB_USER")
    expected_pass = ENV.fetch("SIDEKIQ_WEB_PASSWORD")

    ActiveSupport::SecurityUtils.secure_compare(
      ::Digest::SHA256.hexdigest(username),
      ::Digest::SHA256.hexdigest(expected_user)
    ) &
      ActiveSupport::SecurityUtils.secure_compare(
        ::Digest::SHA256.hexdigest(password),
        ::Digest::SHA256.hexdigest(expected_pass)
      )
  end
end
