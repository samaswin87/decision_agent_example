# Default Adapter Use Case
# Demonstrates the default DecisionAgent RBAC adapter configuration
# This example shows how the default adapter works without external authentication/authorization libraries
class DefaultAdapterUseCase
  RULE_ID = 'default_adapter_example'

  def self.rules_definition
    {
      version: "1.0",
      ruleset: "default_adapter",
      description: "Default adapter rules using built-in DecisionAgent RBAC system",
      rules: [
        {
          id: "admin_full_access",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "admin" }
            ]
          },
          then: {
            decision: "allowed",
            weight: 1.0,
            reason: "Admin has full access using default adapter",
            metadata: {
              adapter_type: "default",
              access_level: "full"
            }
          }
        },
        {
          id: "editor_content_access",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "editor" },
              {
                any: [
                  { field: "action", op: "eq", value: "view" },
                  { field: "action", op: "eq", value: "edit" },
                  { field: "action", op: "eq", value: "create" }
                ]
              },
              { field: "resource_type", op: "eq", value: "content" }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.9,
            reason: "Editor can manage content using default adapter",
            metadata: {
              adapter_type: "default",
              access_level: "content_management"
            }
          }
        },
        {
          id: "viewer_read_only",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "viewer" },
              { field: "action", op: "eq", value: "view" }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.8,
            reason: "Viewer can read resources using default adapter",
            metadata: {
              adapter_type: "default",
              access_level: "read_only"
            }
          }
        },
        {
          id: "viewer_write_denied",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "viewer" },
              {
                any: [
                  { field: "action", op: "eq", value: "edit" },
                  { field: "action", op: "eq", value: "create" },
                  { field: "action", op: "eq", value: "delete" }
                ]
              }
            ]
          },
          then: {
            decision: "denied",
            weight: 1.0,
            reason: "Viewer cannot perform write operations using default adapter",
            metadata: {
              adapter_type: "default",
              access_level: "read_only"
            }
          }
        },
        {
          id: "default_deny",
          if: {
            all: []
          },
          then: {
            decision: "denied",
            weight: 0.5,
            reason: "Default deny - no matching rule found",
            metadata: {
              adapter_type: "default"
            }
          }
        }
      ]
    }
  end

  # Example: Simple authorization class using default adapter
  class DefaultAuthorizer
    def initialize(user_role, user_id = nil)
      @user_role = user_role
      @user_id = user_id
    end

    def can?(action, resource_type: 'public', resource_owner: nil)
      context = {
        user_id: @user_id || 'anonymous',
        user_role: @user_role,
        action: action.to_s,
        resource_type: resource_type.to_s,
        resource_owner: resource_owner || @user_id
      }

      result = DefaultAdapterUseCase.evaluate(context)
      result[:decision] == 'allowed'
    end

    def authorize!(action, resource_type: 'public', resource_owner: nil)
      unless can?(action, resource_type: resource_type, resource_owner: resource_owner)
        raise "Authorization failed: #{@user_role} cannot #{action} #{resource_type}"
      end
    end
  end

  def self.evaluate(context)
    service = DecisionService.instance
    result = service.evaluate(
      rule_id: RULE_ID,
      context: context
    )

    format_result(result, context)
  end

  def self.setup_rules
    service = DecisionService.instance

    rule = Rule.find_or_initialize_by(rule_id: RULE_ID)
    rule.ruleset = 'default_adapter'
    rule.description = 'Default adapter integration example'
    rule.status = 'active'
    rule.save!

    unless rule.active_version
      version = service.save_rule_version(
        rule_id: RULE_ID,
        content: rules_definition,
        created_by: 'system',
        changelog: 'Initial default adapter example'
      )
      version.activate!
    end
  end

  # Example usage: Demonstrate default adapter
  def self.simulate_default_adapter
    setup_rules

    results = []

    # Test admin access
    admin_authorizer = DefaultAuthorizer.new('admin', 'user_1')
    results << {
      user_role: 'admin',
      action: 'view',
      resource_type: 'content',
      can: admin_authorizer.can?(:view, resource_type: 'content'),
      adapter: 'default'
    }

    results << {
      user_role: 'admin',
      action: 'delete',
      resource_type: 'content',
      can: admin_authorizer.can?(:delete, resource_type: 'content'),
      adapter: 'default'
    }

    # Test editor access
    editor_authorizer = DefaultAuthorizer.new('editor', 'user_2')
    results << {
      user_role: 'editor',
      action: 'edit',
      resource_type: 'content',
      can: editor_authorizer.can?(:edit, resource_type: 'content'),
      adapter: 'default'
    }

    results << {
      user_role: 'editor',
      action: 'delete',
      resource_type: 'content',
      can: editor_authorizer.can?(:delete, resource_type: 'content'),
      adapter: 'default'
    }

    # Test viewer access
    viewer_authorizer = DefaultAuthorizer.new('viewer', 'user_3')
    results << {
      user_role: 'viewer',
      action: 'view',
      resource_type: 'content',
      can: viewer_authorizer.can?(:view, resource_type: 'content'),
      adapter: 'default'
    }

    results << {
      user_role: 'viewer',
      action: 'edit',
      resource_type: 'content',
      can: viewer_authorizer.can?(:edit, resource_type: 'content'),
      adapter: 'default'
    }

    # Test authorization exceptions
    begin
      viewer_authorizer.authorize!(:delete, resource_type: 'content')
      results << {
        user_role: 'viewer',
        action: 'delete',
        resource_type: 'content',
        authorized: true,
        adapter: 'default'
      }
    rescue => e
      results << {
        user_role: 'viewer',
        action: 'delete',
        resource_type: 'content',
        authorized: false,
        error: e.message,
        adapter: 'default'
      }
    end

    results
  end

  private

  def self.format_result(result, context)
    {
      context: context,
      decision: result[:decision] || 'denied',
      confidence: result[:confidence] || 0,
      explanations: result[:explanations] || [],
      metadata: result[:evaluations]&.first&.dig(:metadata) || {},
      evaluated_at: Time.current
    }
  end
end

