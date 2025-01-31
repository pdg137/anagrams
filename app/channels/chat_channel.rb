class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from params[:room]
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def say(data)
    message = data['message']
    ActionCable.server.broadcast(params[:room], "Someone said: #{message}")
  end
end
