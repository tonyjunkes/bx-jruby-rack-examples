class DeskController < ApplicationController
    def dashboard
        @tickets = Ticket.includes(:customer, :assignee).order(updated_at: :desc, id: :desc).limit(5)
        render 'desk/dashboard'
    end

    def identity
        session[:agent_id] = Agent.find(params[:agent_id]).id
        session[:notice] = 'Demo agent changed.'
        redirect_to root_path, status: :see_other
    end
end
