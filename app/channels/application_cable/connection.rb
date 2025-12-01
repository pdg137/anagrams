module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :nickname

    NICKNAME_COOKIE = 'nickname'.freeze
    NICKNAME_REGEX = /\A[A-Za-z0-9]+\z/.freeze

    def connect
      self.nickname = cookie_nickname || 'Someone'
    end

    private

    def cookie_nickname
      value = cookies[NICKNAME_COOKIE].to_s.strip
      return nil if value.blank?
      return value if value.match?(NICKNAME_REGEX)
    end
  end
end
