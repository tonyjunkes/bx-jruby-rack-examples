class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    before_action { response.headers['Cache-Control'] = 'no-store' }
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActionController::InvalidAuthenticityToken do
        render plain: 'Invalid authenticity token. Reload the form and try again.', status: :forbidden
    end

    def not_found
        render 'desk/not_found', status: :not_found
    end
end
