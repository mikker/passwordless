module Passwordless
  class Session < ApplicationRecord
    belongs_to :authenticatable, polymorphic: true

    validates \
      :timeout_at,
      :expires_at,
      :user_agent,
      :remote_addr,
      :token,
      presence: true

    before_validation :set_defaults

    scope :valid, lambda {
      where('timeout_at > ? AND expires_at > ?', Time.current, Time.current)
    }

    private

    def set_defaults
      self.expires_at ||= 1.year.from_now
      self.timeout_at ||= 1.hour.from_now
      self.token ||= loop do
        token = Passwordless.token_generator.call(self)
        break token unless Session.find_by(token: token)
      end
    end
  end
end
