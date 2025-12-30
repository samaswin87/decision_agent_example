# Permission Checkable Concern
# Provides permission checking using DecisionAgent RBAC system
module PermissionCheckable
  extend ActiveSupport::Concern

  included do
    before_action :ensure_rbac_rules_setup
  end

  # Check if current user has permission for an action
  # @param action [String] The action to check (e.g., 'view', 'edit', 'delete', 'approve', 'export', 'batch')
  # @param resource_type [String] Optional resource type (default: 'public')
  # @param resource_owner [String] Optional resource owner ID
  # @return [Boolean] true if allowed, false if denied
  def check_permission(action:, resource_type: 'public', resource_owner: nil, amount: nil)
    user_role = current_user_role
    user_id = current_user_id

    # Build context for RBAC evaluation
    context = {
      user_id: user_id,
      user_role: user_role,
      action: action.to_s,
      resource_type: resource_type.to_s,
      resource_owner: resource_owner || user_id,
      is_own_resource: (resource_owner.nil? || resource_owner == user_id)
    }

    # Add amount for approval actions
    context[:amount] = amount.to_f if amount.present? && action.to_s == 'approve'

    # Evaluate using RBAC use case
    result = RbacUseCase.evaluate(context)

    decision = result[:decision]
    allowed = decision == 'allowed'

    # Log permission check
    Rails.logger.info("Permission check: user_role=#{user_role}, action=#{action}, decision=#{decision}, reason=#{result[:explanations]&.first}")

    allowed
  end

  # Require permission or redirect/deny access
  # @param action [String] The action to check
  # @param resource_type [String] Optional resource type
  # @param resource_owner [String] Optional resource owner ID
  # @param amount [Float] Optional amount for approval actions
  def require_permission!(action:, resource_type: 'public', resource_owner: nil, amount: nil)
    unless check_permission(action: action, resource_type: resource_type, resource_owner: resource_owner, amount: amount)
      handle_permission_denied(action)
    end
  end

  # Get current user role from session
  # Defaults to 'viewer' if not set (for testing purposes)
  def current_user_role
    session[:user_role] || 'viewer'
  end

  # Get current user ID from session
  def current_user_id
    session[:user_id] || 'anonymous'
  end

  # Set user role in session (for testing)
  def set_user_role(role)
    session[:user_role] = role
    session[:user_id] ||= "user_#{SecureRandom.hex(4)}"
  end

  private

  def ensure_rbac_rules_setup
    RbacUseCase.setup_rules
  rescue StandardError => e
    Rails.logger.error("Failed to setup RBAC rules: #{e.message}")
  end

  def handle_permission_denied(action)
    if request.format.json? || request.xhr?
      render json: {
        error: 'Permission denied',
        message: "You do not have permission to perform action: #{action}",
        user_role: current_user_role,
        action: action
      }, status: :forbidden
    else
      flash[:alert] = "Permission denied: You do not have permission to perform action '#{action}' with role '#{current_user_role}'"
      redirect_to root_path
    end
  end
end

