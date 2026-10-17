# Request-scoped actions used by this application's explicit routes.
module DeskActions
    def overview
        @tickets = Ticket.includes(:customer, :assignee).order(updated_at: :desc, id: :desc).limit(5)
        render_page('dashboard')
    end

    def ticket_list
        scope = Ticket.filtered(params)
        @total = scope.count
        @pages = [(@total / 20.0).ceil, 1].max
        @page = [[params['page'].to_i, 1].max, @pages].min
        @tickets = scope.offset((@page - 1) * 20).limit(20)
        render_page('tickets')
    end

    def ticket_new
        @ticket = Ticket.new(status: 'open', priority: 'normal')
        render_page('ticket_form')
    end

    def ticket_show(id)
        @ticket = Ticket.find(id)
        render_page('ticket')
    end

    def ticket_edit(id)
        @ticket = Ticket.find(id)
        render_page('ticket_form')
    end

    def ticket_save(id = nil)
        @ticket = id ? Ticket.find(id) : Ticket.new
        @ticket.assign_attributes(attributes('ticket', %w[title description customer_id assignee_id priority status]))
        if @ticket.save
            session[:notice] = 'Ticket saved.'
            redirect_page('/tickets/' + @ticket.id.to_s)
        else
            @errors = @ticket.errors.full_messages
            render_page('ticket_form', 422)
        end
    end

    def comment_save(id)
        @ticket = Ticket.find(id)
        @comment_body = attributes('comment', %w[body])['body']
        comment = @ticket.comments.build(body: @comment_body, agent: current_agent)
        if comment.save
            @ticket.touch
            session[:notice] = 'Comment added.'
            redirect_page('/tickets/' + @ticket.id.to_s)
        else
            @errors = comment.errors.full_messages
            render_page('ticket', 422)
        end
    end

    def customer_list
        render_page('customers')
    end

    def customer_new
        @customer = Customer.new
        render_page('customer_form')
    end

    def customer_show(id)
        @customer = Customer.find(id)
        @tickets = @customer.tickets.includes(:customer, :assignee).order(updated_at: :desc, id: :desc)
        render_page('customer')
    end

    def customer_edit(id)
        @customer = Customer.find(id)
        render_page('customer_form')
    end

    def customer_save(id = nil)
        @customer = id ? Customer.find(id) : Customer.new
        @customer.assign_attributes(attributes('customer', %w[name company email]))
        if @customer.save
            session[:notice] = 'Customer saved.'
            redirect_page('/customers/' + @customer.id.to_s)
        else
            @errors = @customer.errors.full_messages
            render_page('customer_form', 422)
        end
    end

    def identity_save
        session[:agent_id] = Agent.find(params['agent_id']).id
        session[:notice] = 'Demo agent changed.'
        redirect_page('/')
    end

    # Accept only scalar, allowlisted fields; never mass-assign client parameters.
    def attributes(group, allowed)
        input = params[group]
        return {} unless input.is_a?(Hash)
        input.select { |key, value| allowed.include?(key) && value.is_a?(String) }
    end
end
