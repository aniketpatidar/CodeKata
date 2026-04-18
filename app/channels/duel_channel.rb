class DuelChannel < ApplicationCable::Channel
  def subscribed
    duel = Duel.find_by(id: params[:duel_id])
    stream_from "duel_#{duel.id}" if duel&.participant?(current_user)
  end

  def unsubscribed
  end
end
