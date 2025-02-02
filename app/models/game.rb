class Game < ApplicationRecord
  def hidden_letters
    log_update
    @hidden_letters
  end

  def visible_letters
    log_update
    @visible_letters
  end

  def words
    log_update
    @words
  end

  def log_update
    return if log == @last_log

    lines = log.split("\n")
    @hidden_letters = []
    @visible_letters = []
    @words = {}

    lines.each_with_index do |line, l|
      line_number = l + 1
      if line_number == 1
        @hidden_letters = line.split(//)
        next
      end

      case line
      when /^(\d+)\+([A-Z])$/
        i = @hidden_letters.index($2)
        if !i
          raise LogError.new("line #{line_number}: invalid flip #{$2}; " +
                             "hidden letters are #{@hidden_letters.join('')}")
        end

        @hidden_letters.delete_at(i)
        @visible_letters.push($2)
      when /^(\d+):([A-Z]+)$/
        steal_word($2, line_number)
        @words[$1.to_i] ||= []
        @words[$1.to_i].push($2)
      end
    end

    @last_log = log
  end

  # returns a hash of counts for each item in the array
  def count(array)
    array.group_by(&:itself)
      .map{|k,v| [k, v.count] }.to_h
  end

  def is_within?(smaller, larger)
    # accept string, array, or count
    smaller = smaller.chars if smaller.is_a? String
    larger = larger.chars if larger.is_a? String
    smaller = count(smaller) if smaller.is_a? Array
    larger = count(larger) if larger.is_a? Array

    smaller.all? { |l, c| larger[l].to_i >= c }
  end

  def subtract(smaller, larger)
    # accept string, array, or count
    smaller = smaller.chars if smaller.is_a? String
    larger = larger.chars if larger.is_a? String
    smaller = count(smaller) if smaller.is_a? Array
    larger = count(larger) if larger.is_a? Array

    larger.map { |l, c| [l, c - smaller[l].to_i] }
      .reject { |a| a[1] == 0 }
      .to_h
  end

  def steal_word(word, line_number)
    letter_counts = count(word.chars)

    # case 1 - in the visible letters
    visible_letter_counts = count(@visible_letters)

    if letter_counts.all? { |l, c| visible_letter_counts[l].to_i >= c }
      word.chars.each do |l|
        i = @visible_letters.index(l)
        @visible_letters.delete_at(i)
      end

      return
    end

    # case 2 - stealing 1 word
    players = @words.keys.sort # TODO: fair ordering
    players.each do |player|
      @words[player].each_with_index do |w, i|
        next if word.include?(w) # substring rule
        next if !is_within?(w, letter_counts)

        remaining_letters = subtract(w, letter_counts)

        next if !is_within?(remaining_letters, @visible_letters)

        # steal possible!
        @words[player].delete_at(i)
        remaining_letters.each do |l, c|
          c.times do
            i = @visible_letters.index(l)
            @visible_letters.delete_at(i)
          end
        end

        return
      end
    end

    raise LogError.new("line #{line_number}: can't make word #{word}")
  end
end
