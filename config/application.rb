require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module CatHerderApi
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w[assets tasks])

    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address:              "smtp.gmail.com",
      port:                 587,
      domain:               "gmail.com",
      user_name:            ENV["GMAIL_USERNAME"],
      password:             ENV["GMAIL_APP_PASSWORD"],
      authentication:       :plain,
      enable_starttls_auto: true
    }
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = true
  end
end
