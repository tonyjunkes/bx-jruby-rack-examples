require 'bundler/setup'
require 'rails'
require 'action_controller/railtie'
require 'active_record/railtie'
Bundler.require(*Rails.groups)

module Fieldwork
    class Application < Rails::Application
        config.load_defaults 7.2
        config.eager_load = false
        config.secret_key_base = ENV.fetch('SESSION_SECRET')
        config.hosts = ['localhost', '127.0.0.1', '[::1]']
        config.logger = Logger.new($stderr)
        config.log_level = :info
        config.public_file_server.enabled = true
        config.session_store :cookie_store, key: '_fieldwork_rails', path: '/ruby', same_site: :lax, httponly: true
        config.action_controller.allow_forgery_protection = true
        # This demo keeps one framework instance per worker; restart to load Ruby changes.
        config.enable_reloading = false
        config.active_record.dump_schema_after_migration = false
    end
end
