class ChatChannel < ApplicationCable::Channel
  def subscribed
    p params
    stream_from "chat"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def say(data)
    message = data['message']
    ActionCable.server.broadcast("chat", "Someone said: #{message}")
  end
end
