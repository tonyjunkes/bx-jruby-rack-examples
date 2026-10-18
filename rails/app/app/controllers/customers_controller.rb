class CustomersController < ApplicationController
    def index
        render 'desk/customers'
    end

    def show
        @customer = Customer.find(params[:id])
        @tickets = @customer.tickets.includes(:customer, :assignee).order(updated_at: :desc, id: :desc)
        render 'desk/customer'
    end

    def new
        @customer = Customer.new
        render 'desk/customer_form'
    end

    def edit
        @customer = Customer.find(params[:id])
        render 'desk/customer_form'
    end

    def create
        @customer = Customer.new(customer_attributes)
        save_customer
    end

    def update
        @customer = Customer.find(params[:id])
        @customer.assign_attributes(customer_attributes)
        save_customer
    end

    private

    def customer_attributes
        params.fetch(:customer, ActionController::Parameters.new).permit(:name, :company, :email)
    end

    def save_customer
        if @customer.save
            session[:notice] = 'Customer saved.'
            redirect_to request.script_name + '/customers/' + @customer.id.to_s, status: :see_other
        else
            @errors = @customer.errors.full_messages
            render 'desk/customer_form', status: :unprocessable_entity
        end
    end
end
