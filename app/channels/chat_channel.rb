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

    if message.to_s.strip == '/look'
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

    words_by_player = (game.words || {}).sort_by { |player, _| player.to_i }
    word_lines = words_by_player.filter_map do |player, player_words|
      next if player_words.empty?
      "Player #{player}: #{player_words.join(' ')}"
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
