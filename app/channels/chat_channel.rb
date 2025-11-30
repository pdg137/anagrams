class ChatChannel < ApplicationCable::Channel
  WORD_REGEX = /\A[A-Za-z]+\z/.freeze
  NICKNAME_REGEX = /\A[A-Za-z0-9]+\z/.freeze

  def subscribed
    stream_from params[:room]
    broadcast "#{nickname} connected"
  end

  def unsubscribed
    broadcast "#{nickname} disconnected"
  end

  def say(data)
    message = data['message'].to_s
    stripped_message = message.strip

    if stripped_message.start_with?('/')
      handle_command(stripped_message)
      return
    end

    if stripped_message.match?(WORD_REGEX) && game
      word = stripped_message.upcase
      if game.try_steal(nickname, word)
        broadcast "#{nickname} made #{word}"
        return
      end
    end

    broadcast "#{nickname} said: #{stripped_message}"
  end

  def broadcast(line)
    ActionCable.server.broadcast(params[:room], { chat: line, status: look_state })
  end

  private

  def look_state
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

    ([visible_line] + word_lines).join("\n")
  end

  def game
    @game ||= find_game
  end

  def find_game
    params[:room] =~ /^game-(\d+)$/
    Game.find_by(id: $1.to_i)
  end

  def handle_command(command_line)
    body = command_line[1..]
    command_name, args = body.to_s.split(/\s+/, 2)

    case normalize_command(command_name)
    when :nick
      handle_nick_command(args)
    when :look
      handle_look_command
    when :flip
      handle_flip_command
    else
      transmit_error("Unknown command: #{command_line}")
    end
  end

  def normalize_command(name)
    case name.downcase
    when 'nick', 'n'
      :nick
    when 'look', 'l'
      :look
    when 'flip', 'f'
      :flip
    end
  end

  def handle_nick_command(argument)
    desired_nickname = argument.to_s.strip
    if desired_nickname.match?(NICKNAME_REGEX)
      broadcast "#{nickname} set nickname to #{desired_nickname}"
      connection.nickname = desired_nickname
    else
      transmit_error("Invalid nickname: #{desired_nickname}")
    end
  end

  def handle_look_command
    connection.transmit identifier: @identifier, message: { status: look_state }
  end

  def handle_flip_command
    letter = game.flip(nickname)
    broadcast "#{nickname} flipped #{letter}"
  end

  def transmit_error(message)
    connection.transmit identifier: @identifier, message: { chat: message }
  end
end
