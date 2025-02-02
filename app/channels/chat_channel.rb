class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from params[:room]
    broadcast "#{nickname} connected"
  end

  def unsubscribed
    broadcast "#{nickname} disconnected"
  end

  def say(data)
    message = data['message']
    if message =~ %r(^/nick\s+(.*))
      broadcast "#{nickname} set nickname to #{$1}"
      connection.nickname = $1
      return
    end

    broadcast "#{nickname} said: #{message}"
  end

  def broadcast(line)
    ActionCable.server.broadcast(params[:room], line)
  end
end
