require 'bundler/setup'
require 'active_record'
require 'logger'
require 'fileutils'
require 'rack'

APP_ROOT = File.expand_path('..', __dir__)
DATABASE_PATH = ENV.fetch('DESK_DATABASE')
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: DATABASE_PATH, pool: 5, timeout: 5000)
%w[application_record agent customer ticket comment].each do |name|
    require File.join(APP_ROOT, 'app/models', name)
end
require_relative 'desk_helpers'
