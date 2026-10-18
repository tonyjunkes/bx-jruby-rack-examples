class TicketsController < ApplicationController
    def index
        scope = Ticket.filtered(params)
        @total = scope.count
        @pages = [(@total / 20.0).ceil, 1].max
        @page = [[params[:page].to_i, 1].max, @pages].min
        @tickets = scope.offset((@page - 1) * 20).limit(20)
        render 'desk/tickets'
    end

    def show
        @ticket = Ticket.find(params[:id])
        render 'desk/ticket'
    end

    def new
        @ticket = Ticket.new(status: 'open', priority: 'normal')
        render 'desk/ticket_form'
    end

    def edit
        @ticket = Ticket.find(params[:id])
        render 'desk/ticket_form'
    end

    def create
        @ticket = Ticket.new(ticket_attributes)
        save_ticket
    end

    def update
        @ticket = Ticket.find(params[:id])
        @ticket.assign_attributes(ticket_attributes)
        save_ticket
    end

    private

    def ticket_attributes
        params.fetch(:ticket, ActionController::Parameters.new).permit(:title, :description, :customer_id, :assignee_id, :priority, :status)
    end

    def save_ticket
        if @ticket.save
            session[:notice] = 'Ticket saved.'
            redirect_to request.script_name + '/tickets/' + @ticket.id.to_s, status: :see_other
        else
            @errors = @ticket.errors.full_messages
            render 'desk/ticket_form', status: :unprocessable_entity
        end
    end
end
