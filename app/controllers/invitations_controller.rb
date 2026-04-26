# app/controllers/invitations_controller.rb
class InvitationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @users = User.all
    @invitations = current_user.invitations
    @friends = current_user.friends
  end

  def create
    @user = User.find(params[:user_id])
    current_user.send_invitation(@user)
    respond_to do |format|
      turbo_stream.append("friendsList", partial: "friend", locals: { friend: @user })
    end
  end

  def accept
    @invitation = current_user.pending_invitations.find(params[:id])
    @invitation.update(confirmed: true)
    respond_to do |format|
      render turbo_stream: [
        turbo_stream.remove(@invitation),
        turbo_stream.append("friendsList", partial: "friend", locals: { friend: @invitation.friend })
      ]
    end
  end

  def decline
    invitation = Invitation.find(params[:id])
    unless invitation.user == current_user || invitation.friend == current_user
      return redirect_to invitations_path, alert: "Not authorized"
    end
    invitation.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(dom_id(invitation)) }
      format.html { redirect_to invitations_path }
    end
  end
end
