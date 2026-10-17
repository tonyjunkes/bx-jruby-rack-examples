require_relative '../../lib/desk_helpers'

module ApplicationHelper
    include DeskHelpers

    def partial(name)
        render partial: 'desk/' + name
    end

    def csrf_field
        hidden_field_tag :authenticity_token, form_authenticity_token
    end
end
