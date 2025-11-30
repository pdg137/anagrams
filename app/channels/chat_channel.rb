class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from params[:room]
    broadcast "#{nickname} connected"
  end

  def unsubscribed
    broadcast "#{nickname} disconnected"
  end

  def say(data)
    message = data['message'].to_s
    if (match = message.match(%r{\A/nick\s+(\w+)\z}))
      new_nickname = match[1]
      broadcast "#{nickname} set nickname to #{new_nickname}"
      connection.nickname = new_nickname
      return
    end

    if message.strip == '/look'
      connection.transmit identifier: @identifier, message: look_state
      return
    end

    broadcast "#{nickname} said: #{message}"
  end

  def broadcast(line)
    ActionCable.server.broadcast(params[:room], line)
  end

  private

  def look_state
    return 'Unable to determine board state for this room.' unless game

    visible_line = if game.visible_letters.present?
                     "Visible letters: #{game.visible_letters.join(' ')}"
                   else
                     'Visible letters: (none)'
                   end

    word_lines = game.words.filter_map do |player, player_words|
      next if player_words.empty?
      "#{player}: #{player_words.join(' ')}"
    end
    word_lines = ['No words have been played yet.'] if word_lines.empty?

    ([visible_line] + word_lines).join("\n") + "\n"
  end

  def game
    return @game if defined?(@game)

    match = params[:room].to_s.match(/^game-(\d+)$/)
    @game = match ? Game.find_by(id: match[1].to_i) : nil
  end
end
