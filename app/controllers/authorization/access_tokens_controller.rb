module Authorization
  class AccessTokensController < ApplicationController
    skip_before_action :enforce_permission
    skip_before_action :resolve_current_user
    skip_before_action :assign_available_users

    def create
      issued_token = Authorization::AccessTokenService.new.issue_token(params[:user_id])
      return redirect_to root_path if issued_token.failure?

      cookies[:access_token] = {
        value: issued_token.data,
        httponly: true,
        expires: Authorization::AccessToken::EXPIRATION_DURATION.from_now
      }

      redirect_to root_path
    end
  end
end
