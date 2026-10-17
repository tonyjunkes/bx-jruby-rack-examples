require 'uri'

module DeskHelpers
    def label(value)
        value.to_s.tr('_', ' ').split.map(&:capitalize).join(' ')
    end

    def url(path)
        "#{request.script_name}#{path}"
    end

    def current_agent
        @current_agent ||= Agent.find_by(id: session[:agent_id]) || Agent.order(:id).first
    end

    def agents
        @agents ||= Agent.order(:name).to_a
    end

    def page_url(number)
        filters = %w[q status priority assignee].to_h { |key| [key, params[key].to_s] }
        url('/tickets?' + URI.encode_www_form(filters.merge('page' => number)))
    end

    def selected(actual, expected)
        actual.to_s == expected.to_s ? 'selected' : ''
    end

    def timestamp(value)
        value.utc.strftime('%b %d, %Y at %H:%M UTC')
    end
end
