# DecisionAgent Configuration
# This initializer sets up the decision_agent gem with proper configuration

Rails.application.config.to_prepare do
  # Configure DecisionAgent if needed
  # DecisionAgent.configure do |config|
  #   config.cache_enabled = true
  #   config.logger = Rails.logger
  # end

  # Configure RBAC (Role-Based Access Control)
  # Using default built-in RBAC system
  # You can also configure custom adapters for Devise, CanCanCan, Pundit, etc.
  # See docs/RBAC_CONFIGURATION.md for more options
  DecisionAgent.configure_rbac(:default)

  # Ensure singleton service is initialized
  DecisionService.instance

  Rails.logger.info "DecisionAgent initialized successfully with RBAC"
end

# Thread-safe initialization for multi-threaded environments (Puma, Sidekiq)
# The DecisionService uses Singleton pattern with Mutex for thread safety
Rails.application.config.after_initialize do
  if defined?(Puma) || defined?(Sidekiq)
    Rails.logger.info "Multi-threaded environment detected - DecisionService thread-safety enabled"
  end
end
