class ApplicationController < ActionController::Base
  class UndeclaredPermissionError < StandardError; end

  allow_browser versions: :modern

  stale_when_importmap_changes

  class_attribute :permission_declarations, default: {}

  before_action :resolve_current_user
  before_action :assign_available_users
  before_action :enforce_permission

  helper_method :allowed_to?

  def self.requires_permission(permission, only: :every_action)
    declared_actions = Array(only)
    self.permission_declarations = permission_declarations.merge(declared_actions.index_with { permission })
  end

  private

  def allowed_to?(permission)
    Authorization::Permissions.new.allows?(user: Current.user, permission: permission)
  end

  def enforce_permission
    raise UndeclaredPermissionError, undeclared_permission_message if required_permission.blank?
    return require_sign_in if Current.user.blank?
    return if allowed_to?(required_permission)

    head :forbidden
  end

  def require_sign_in
    return head :unauthorized unless request.format.html?

    redirect_to sign_in_path
  end

  def required_permission
    permission_declarations[action_name.to_sym] || permission_declarations[:every_action]
  end

  def undeclared_permission_message
    "#{self.class.name}##{action_name} has no permission declared. Add `requires_permission` or skip the enforcer."
  end

  def report_failure(result)
    flash[:alert] = failure_message(result.error)
  end

  def failure_message(error)
    return error.message if error.respond_to?(:message)

    error.to_s.humanize
  end

  def resolve_current_user
    authentication = Authorization::AccessTokenService.new.authenticated_user(cookies[:access_token])
    Current.user = authentication.data if authentication.success?
  end

  def assign_available_users
    @available_users = User.order(:email)
  end
end
