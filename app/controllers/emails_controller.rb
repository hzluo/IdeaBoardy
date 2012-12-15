class EmailsController < ApplicationController

  def invitation
    board = Board.find(params[:board][:id])
    email = BoardMailer.invitation_email(request.host_with_port, params[:to], board)
    email.deliver
    render :json => {result: "success"}
  end
end