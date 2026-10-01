require "jwt"

module Authorization
  class AccessToken
    EXPIRATION_DURATION = 1.hour
    ALGORITHM = "HS256"

    attr_reader :token

    def self.encode(user)
      payload = { user_id: user.id, exp: EXPIRATION_DURATION.from_now.to_i }
      new(JWT.encode(payload, signing_key, ALGORITHM))
    end

    def self.signing_key
      Rails.application.credentials.jwt_signing_key || ENV["JWT_SIGNING_KEY"] || Rails.application.secret_key_base
    end

    def initialize(token)
      @token = token
    end

    def decoded_payload
      return @decoded_payload if defined?(@decoded_payload)

      @decoded_payload = JWT.decode(@token, self.class.signing_key, true, algorithm: ALGORITHM).first
    rescue JWT::DecodeError
      @decoded_payload = nil
    end

    def user_id
      decoded_payload&.fetch("user_id", nil)
    end
  end
end
