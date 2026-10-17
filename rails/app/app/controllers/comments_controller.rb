class CommentsController < ApplicationController
    def create
        @ticket = Ticket.find(params[:id])
        @comment_body = params.fetch(:comment, ActionController::Parameters.new).permit(:body)[:body]
        agent = Agent.find_by(id: session[:agent_id]) || Agent.order(:id).first
        comment = @ticket.comments.build(body: @comment_body, agent: agent)
        if comment.save
            @ticket.touch
            session[:notice] = 'Comment added.'
            redirect_to request.script_name + '/tickets/' + @ticket.id.to_s, status: :see_other
        else
            @errors = comment.errors.full_messages
            render 'desk/ticket', status: :unprocessable_entity
        end
    end
end
