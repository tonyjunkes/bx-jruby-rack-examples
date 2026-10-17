require_relative 'boot'
require_relative 'desk_actions'
require 'sinatra/base'
require 'rack/protection/authenticity_token'
require 'cgi'

class DeskApplication < Sinatra::Base
    set :run, false
    set :environment, ENV.fetch('RACK_ENV', 'development').to_sym
    set :root, APP_ROOT
    set :views, File.join(APP_ROOT, 'views')
    set :public_folder, File.join(APP_ROOT, 'public')
    set :static, true
    set :show_exceptions, false
    set :raise_errors, true
    set :sessions, key: '_fieldwork_sinatra', secret: ENV.fetch('SESSION_SECRET'), path: '/ruby', same_site: :lax, httponly: true
    set :host_authorization, permitted_hosts: ['localhost', '127.0.0.1', '[::1]']
    use Rack::Protection::AuthenticityToken

    helpers DeskHelpers, DeskActions

    helpers do
        def h(value)
            CGI.escapeHTML(value.to_s)
        end

        def csrf_field
            token = Rack::Protection::AuthenticityToken.token(session)
            %(<input type="hidden" name="authenticity_token" value="#{h(token)}">)
        end

        def partial(name)
            erb name.to_sym, layout: false
        end

        def render_page(name, code = 200)
            status code
            headers 'cache-control' => 'no-store'
            @content = partial(name)
            erb :layout, layout: false
        end

        def redirect_page(path)
            redirect url(path), 303
        end
    end

    get('/') { overview }
    get('/tickets') { ticket_list }
    get('/tickets/new') { ticket_new }
    post('/tickets') { ticket_save }
    get('/tickets/:id') { ticket_show(params['id']) }
    get('/tickets/:id/edit') { ticket_edit(params['id']) }
    post('/tickets/:id') { ticket_save(params['id']) }
    post('/tickets/:id/comments') { comment_save(params['id']) }
    get('/customers') { customer_list }
    get('/customers/new') { customer_new }
    post('/customers') { customer_save }
    get('/customers/:id') { customer_show(params['id']) }
    get('/customers/:id/edit') { customer_edit(params['id']) }
    post('/customers/:id') { customer_save(params['id']) }
    post('/identity') { identity_save }

    error ActiveRecord::RecordNotFound do
        render_page('not_found', 404)
    end

    not_found do
        render_page('not_found', 404)
    end
end
