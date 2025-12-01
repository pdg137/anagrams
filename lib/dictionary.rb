class Dictionary
  class MissingDictionaryError < StandardError; end

  class << self
    def check(word)
      return false if blank?(word)

      load_words.key?(normalize(word))
    end

    def reset!
      @words = nil
    end

    private

    def load_words
      @words ||= begin
        path = ENV['DICTIONARY']
        raise MissingDictionaryError, 'DICTIONARY environment variable is not set' if blank?(path)
        raise MissingDictionaryError, "Dictionary file not found: #{path}" unless File.exist?(path)

        words = {}
        File.foreach(path) do |line|
          normalized = normalize(line)
          next if normalized.empty?
          words[normalized] = true
        end
        words
      end
    end

    def normalize(value)
      value.to_s.strip.downcase
    end

    def blank?(value)
      value.to_s.strip.empty?
    end
  end
end
