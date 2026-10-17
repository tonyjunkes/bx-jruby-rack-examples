require_relative 'lib/application'
require 'rack/session/cookie'
require 'rack/protection'

use Rack::Static, urls: ['/assets'], root: File.join(APP_ROOT, 'public')
use Rack::Session::Cookie, key: '_fieldwork_rack', secret: ENV.fetch('SESSION_SECRET'), path: '/ruby', same_site: :lax, httponly: true
use Rack::Protection::AuthenticityToken
run DeskApplication.new
