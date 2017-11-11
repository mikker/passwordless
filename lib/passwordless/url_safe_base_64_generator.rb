module Passwordless
  class UrlSafeBase64Generator
    def call(_session)
      SecureRandom.urlsafe_base64(32)
    end
  end
end
