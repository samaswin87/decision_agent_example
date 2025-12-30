# Permission Middleware for DecisionAgent Web UI
# Wraps the DecisionAgent Web Server to enforce RBAC permissions
class PermissionMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    
    # Ensure RBAC rules are set up (in a thread-safe way)
    begin
      RbacUseCase.setup_rules
    rescue StandardError => e
      logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
      logger.error("Failed to setup RBAC rules: #{e.message}")
    end

    # Get user role from session (Rails session)
    session = env['rack.session'] || {}
    user_role = session['user_role'] || session[:user_role] || 'viewer'
    user_id = session['user_id'] || session[:user_id] || 'anonymous'

    # Determine action based on request path
    action = determine_action(request.path, request.request_method)

    # Build context for RBAC evaluation
    context = {
      user_id: user_id.to_s,
      user_role: user_role.to_s,
      action: action,
      resource_type: 'web_ui',
      resource_owner: user_id.to_s,
      is_own_resource: true
    }

    # Evaluate permission
    begin
      result = RbacUseCase.evaluate(context)
      decision = result[:decision] || result['decision']
    rescue StandardError => e
      logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
      logger.error("Permission evaluation error: #{e.message}")
      decision = 'denied'
      result = { explanations: [e.message] }
    end

    if decision == 'allowed'
      # Permission granted, proceed to the app
      @app.call(env)
    else
      # Permission denied
      handle_permission_denied(env, user_role, action, result)
    end
  rescue StandardError => e
    logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
    logger.error("Permission middleware error: #{e.message}")
    logger.error(e.backtrace.join("\n")) if e.backtrace
    # On error, deny access for safety
    handle_permission_denied(env, user_role || 'unknown', action || 'unknown', { explanations: [e.message] })
  end

  private

  def determine_action(path, method)
    # Map Web UI paths to actions
    case path
    when %r{/decision_agent/rules}
      method == 'POST' || method == 'PUT' || method == 'DELETE' ? 'edit' : 'view'
    when %r{/decision_agent/testing}
      'batch'
    when %r{/decision_agent/export}
      'export'
    when %r{/decision_agent/admin}
      'approve'
    else
      'view' # Default to view for other paths
    end
  end

  def handle_permission_denied(env, user_role, action, result)
    request = Rack::Request.new(env)
    
    explanations = result[:explanations] || result['explanations'] || []
    reason = explanations.first || explanations[0] || 'Access denied by RBAC rules'
    
    accept_header = env['HTTP_ACCEPT'] || ''
    if request.path.start_with?('/decision_agent/api') || 
       accept_header.include?('application/json') ||
       request.path.end_with?('.json')
      # JSON response for API requests
      [
        403,
        { 'Content-Type' => 'application/json' },
        [{
          error: 'Permission denied',
          message: "You do not have permission to access the DecisionAgent Web UI",
          user_role: user_role.to_s,
          action: action.to_s,
          reason: reason
        }.to_json]
      ]
    else
      # HTML response for browser requests
      session = env['rack.session'] || {}
      csrf_token = session['_csrf_token'] || session[:_csrf_token] || ''
      
      html = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>Permission Denied</title>
          <style>
            body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
            .error { color: #d32f2f; }
            .info { color: #666; margin-top: 20px; }
            .role-selector { margin-top: 30px; padding: 20px; background: #f5f5f5; border-radius: 5px; display: inline-block; }
            select, button { padding: 10px; margin: 5px; font-size: 14px; }
          </style>
        </head>
        <body>
          <h1 class="error">Permission Denied</h1>
          <p>You do not have permission to access the DecisionAgent Web UI.</p>
          <div class="info">
            <p><strong>Your Role:</strong> #{Rack::Utils.escape_html(user_role.to_s)}</p>
            <p><strong>Required Action:</strong> #{Rack::Utils.escape_html(action.to_s)}</p>
            <p><strong>Reason:</strong> #{Rack::Utils.escape_html(reason.to_s)}</p>
          </div>
          <div class="role-selector">
            <h3>Test with Different Role</h3>
            <p>For testing purposes, you can change your role:</p>
            <form action="/demo/set_role" method="post">
              <input type="hidden" name="authenticity_token" value="#{Rack::Utils.escape_html(csrf_token.to_s)}">
              <select name="role">
                <option value="admin" #{'selected' if user_role.to_s == 'admin'}>Admin</option>
                <option value="manager" #{'selected' if user_role.to_s == 'manager'}>Manager</option>
                <option value="analyst" #{'selected' if user_role.to_s == 'analyst'}>Analyst</option>
                <option value="operator" #{'selected' if user_role.to_s == 'operator'}>Operator</option>
                <option value="viewer" #{'selected' if user_role.to_s == 'viewer'}>Viewer</option>
              </select>
              <button type="submit">Set Role</button>
            </form>
            <p style="margin-top: 15px; font-size: 12px; color: #999;">
              <a href="/">← Back to Home</a>
            </p>
          </div>
        </body>
        </html>
      HTML

      [
        403,
        { 'Content-Type' => 'text/html' },
        [html]
      ]
    end
  end
end

