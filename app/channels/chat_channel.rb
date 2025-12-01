require 'dictionary'

class ChatChannel < ApplicationCable::Channel
  WORD_REGEX = /\A[A-Za-z]+\z/.freeze
  NICKNAME_REGEX = /\A[A-Za-z0-9]+\z/.freeze
  MOTD = 'Welcome to Anagrams! Type /help for help.'.freeze
  HELP_TEXT = <<~HELP.chomp.freeze
    Available commands:
    /nick NEWNAME - change your nickname (do this first!)
    /flip - flip a new letter
    /help - show this help
    /dict WORD - check if WORD is in the dictionary

    Commands can be abbreviated like /n, /f, etc.

    Type a word to attempt to make/steal that word. Anything
    else will just be spoken in the chat.
  HELP

  def subscribed
    stream_from params[:room]
    broadcast "#{nickname} connected."
    send_motd
  end

  def unsubscribed
    broadcast "#{nickname} disconnected."
  end

  def say(data)
    message = data['message'].to_s
    stripped_message = message.strip

    if stripped_message.start_with?('/')
      handle_command(stripped_message)
      return
    end

    return if !require_nick

    if stripped_message.match?(WORD_REGEX) && game
      word = stripped_message.upcase
      if game.try_steal(word) && game.play_word(nickname, word)
        broadcast "#{nickname} made #{word}.", include_status_update: true
        return
      end
    end

    broadcast "#{nickname} said: #{stripped_message}"
  end

  def broadcast(line, include_status_update: false)
    message = { chat: line }
    message[:status] = look_state if include_status_update
    ActionCable.server.broadcast(params[:room], message)
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

  def handle_command(line)
    command, args = line.to_s.split(/\s+/, 2)

    case command.downcase
    when '/nick', '/n'
      handle_nick_command(args)
    when '/flip', '/f'
      require_nick &&
        handle_flip_command
    when '/help', '/h'
      handle_help_command
    when '/dict', '/d'
      handle_dict_command(args)
    else
      transmit_error("Unknown command: #{command}")
    end
  end

  def handle_nick_command(argument)
    desired_nickname = argument.to_s.strip
    if desired_nickname.match?(NICKNAME_REGEX)
      broadcast "#{nickname} set nickname to #{desired_nickname}."
      connection.nickname = desired_nickname
      transmit_cookie(ApplicationCable::Connection::NICKNAME_COOKIE, desired_nickname)
    else
      transmit_error("Invalid nickname: #{desired_nickname}")
    end
  end

  def handle_help_command
    connection.transmit identifier: @identifier, message: { chat: HELP_TEXT }
  end

  def handle_dict_command(argument)
    word = argument.to_s.strip.upcase
    message =
      if word.empty?
        'Usage: /dict WORD'
      elsif Dictionary.check(word)
        "#{word} is in the dictionary."
      else
        "#{word} is not in the dictionary."
      end
    connection.transmit identifier: @identifier, message: { chat: message }
  end

  def handle_flip_command
    letter = game.flip(nickname)
    broadcast "#{nickname} flipped #{letter}.", include_status_update: true
  end

  def transmit_error(message)
    connection.transmit identifier: @identifier, message: { chat: message }
  end

  def transmit_cookie(name, value)
    connection.transmit identifier: @identifier, message: { cookie: { name: name, value: value } }
  end

  def require_nick
    if nickname_unset?
      connection.transmit identifier: @identifier, message: { chat: 'First please set a nickname with /nick.' }
      false
    else
      true
    end
  end

  def nickname_unset?
    self.nickname == 'Someone'
  end

  def send_motd
    connection.transmit identifier: @identifier, message: { chat: MOTD, status: look_state }
  end
end
