module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :nickname

    def connect
      self.nickname = "Someone"
    end
  end
end
