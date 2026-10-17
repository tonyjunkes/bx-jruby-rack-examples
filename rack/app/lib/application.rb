require_relative 'boot'
require_relative 'desk_actions'
require 'erb'
require 'cgi'
require 'rack/protection/authenticity_token'

# Rack calls a fresh handler for every request; instance variables never cross requests.
class DeskApplication
    def call(env)
        DeskRequest.new(env).dispatch
    end
end

class DeskRequest
    include DeskHelpers
    include DeskActions

    attr_reader :request, :params, :session

    def initialize(env)
        @request = Rack::Request.new(env)
        @params = @request.params
        @session = env.fetch('rack.session')
    end

    def dispatch
        method = request.request_method
        path = request.path_info
        case [method, path]
        when ['GET', '/'], ['GET', ''] then overview
        when ['GET', '/tickets'] then ticket_list
        when ['GET', '/tickets/new'] then ticket_new
        when ['POST', '/tickets'] then ticket_save
        when ['GET', '/customers'] then customer_list
        when ['GET', '/customers/new'] then customer_new
        when ['POST', '/customers'] then customer_save
        when ['POST', '/identity'] then identity_save
        else
            if (match = path.match(%r{\A/tickets/(\d+)(/edit|/comments)?\z}))
                id, suffix = match.captures
                return ticket_show(id) if method == 'GET' && suffix.nil?
                return ticket_edit(id) if method == 'GET' && suffix == '/edit'
                return ticket_save(id) if method == 'POST' && suffix.nil?
                return comment_save(id) if method == 'POST' && suffix == '/comments'
            elsif (match = path.match(%r{\A/customers/(\d+)(/edit)?\z}))
                id, suffix = match.captures
                return customer_show(id) if method == 'GET' && suffix.nil?
                return customer_edit(id) if method == 'GET' && suffix == '/edit'
                return customer_save(id) if method == 'POST' && suffix.nil?
            end
            render_page('not_found', 404)
        end
    rescue ActiveRecord::RecordNotFound
        render_page('not_found', 404)
    rescue Rack::QueryParser::ParameterTypeError, Rack::QueryParser::InvalidParameterError
        [400, { 'content-type' => 'text/plain; charset=utf-8' }, ['Invalid form parameters.']]
    end

    def h(value)
        CGI.escapeHTML(value.to_s)
    end

    def csrf_field
        token = Rack::Protection::AuthenticityToken.token(session)
        %(<input type="hidden" name="authenticity_token" value="#{h(token)}">)
    end

    def partial(name)
        ERB.new(File.read(File.join(APP_ROOT, 'views', name + '.erb'))).result(binding)
    end

    def render_page(name, status = 200)
        @content = partial(name)
        response = Rack::Response.new(partial('layout'), status, { 'content-type' => 'text/html; charset=utf-8', 'cache-control' => 'no-store' })
        response.finish
    end

    def redirect_page(path)
        [303, { 'location' => url(path), 'content-type' => 'text/html; charset=utf-8' }, []]
    end
end
