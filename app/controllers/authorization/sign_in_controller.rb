module Authorization
  class SignInController < ApplicationController
    skip_before_action :enforce_permission

    def show
      redirect_to root_path if Current.user.present?
    end
  end
end
