module Authorization
  class AccessTokenService
    def issue_token(user_id)
      selected_user = User.find_by(id: user_id)
      return Result.failure(:user_not_found) if selected_user.blank?

      Result.success(AccessToken.encode(selected_user).token)
    end

    def authenticated_user(encoded_access_token)
      return Result.failure(:missing_access_token) if encoded_access_token.blank?

      authenticated_user_id = AccessToken.new(encoded_access_token).user_id
      return Result.failure(:invalid_access_token) if authenticated_user_id.blank?

      authenticated_user = User.find_by(id: authenticated_user_id)
      return Result.failure(:user_not_found) if authenticated_user.blank?

      Result.success(authenticated_user)
    end
  end
end
