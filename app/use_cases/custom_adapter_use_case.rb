# Custom Adapter Use Case
# Demonstrates how to create a custom adapter for DecisionAgent
# This example shows how to build a custom adapter that integrates with your own authentication/authorization system
class CustomAdapterUseCase
  RULE_ID = 'custom_adapter_example'

  # Example: Custom User model with custom attributes
  class CustomUser
    attr_reader :id, :email, :department, :security_clearance, :team_id, :permissions

    def initialize(id:, email:, department:, security_clearance:, team_id: nil, permissions: [])
      @id = id
      @email = email
      @department = department
      @security_clearance = security_clearance
      @team_id = team_id
      @permissions = permissions
    end

    def has_permission?(permission)
      permissions.include?(permission)
    end

    def high_clearance?
      security_clearance >= 5
    end

    def low_clearance?
      security_clearance < 3
    end
  end

  # Example: Custom Resource model
  class CustomResource
    attr_reader :id, :name, :department, :classification, :team_id, :created_by

    def initialize(id:, name:, department:, classification:, team_id: nil, created_by: nil)
      @id = id
      @name = name
      @department = department
      @classification = classification
      @team_id = team_id
      @created_by = created_by
    end

    def classified?
      classification == 'classified'
    end

    def public?
      classification == 'public'
    end

    def same_department?(user)
      department == user.department
    end

    def same_team?(user)
      team_id && user.team_id && team_id == user.team_id
    end
  end

  def self.rules_definition
    {
      version: "1.0",
      ruleset: "custom_adapter",
      description: "Custom adapter rules for specialized authorization decisions",
      rules: [
        {
          id: "high_clearance_classified",
          if: {
            all: [
              { field: "security_clearance", op: "gte", value: 5 },
              { field: "resource_classification", op: "eq", value: "classified" },
              { field: "same_department", op: "eq", value: true }
            ]
          },
          then: {
            decision: "allowed",
            weight: 1.0,
            reason: "High clearance user can access classified resources in their department",
            metadata: {
              adapter_type: "custom",
              clearance_required: 5,
              scope: "department_classified"
            }
          }
        },
        {
          id: "team_collaboration",
          if: {
            all: [
              { field: "same_team", op: "eq", value: true },
              {
                any: [
                  { field: "action", op: "eq", value: "view" },
                  { field: "action", op: "eq", value: "edit" },
                  { field: "action", op: "eq", value: "collaborate" }
                ]
              }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.9,
            reason: "Team members can collaborate on team resources",
            metadata: {
              adapter_type: "custom",
              scope: "team"
            }
          }
        },
        {
          id: "custom_permission_check",
          if: {
            all: [
              { field: "has_custom_permission", op: "eq", value: true },
              { field: "action", op: "eq", value: "special_action" }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.95,
            reason: "User has custom permission for special action",
            metadata: {
              adapter_type: "custom",
              scope: "permission_based"
            }
          }
        },
        {
          id: "public_resource_access",
          if: {
            all: [
              { field: "resource_classification", op: "eq", value: "public" },
              { field: "action", op: "eq", value: "view" }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.8,
            reason: "Public resources can be viewed by anyone",
            metadata: {
              adapter_type: "custom",
              scope: "public"
            }
          }
        },
        {
          id: "low_clearance_denied",
          if: {
            all: [
              { field: "security_clearance", op: "lt", value: 3 },
              { field: "resource_classification", op: "eq", value: "classified" }
            ]
          },
          then: {
            decision: "denied",
            weight: 1.0,
            reason: "Low clearance users cannot access classified resources",
            metadata: {
              adapter_type: "custom",
              clearance_required: 3,
              scope: "classified"
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
              adapter_type: "custom"
            }
          }
        }
      ]
    }
  end

  # Custom Adapter class that integrates with DecisionAgent
  class CustomAdapter
    def initialize(user)
      @user = user
    end

    def can?(action, resource)
      context = build_context(action, resource)
      result = CustomAdapterUseCase.evaluate(context)
      result[:decision] == 'allowed'
    end

    def authorize!(action, resource)
      unless can?(action, resource)
        raise "Custom authorization failed: #{@user.email} cannot #{action} #{resource.name}"
      end
    end

    private

    def build_context(action, resource)
      {
        user_id: @user.id,
        user_email: @user.email,
        user_department: @user.department,
        security_clearance: @user.security_clearance,
        user_team_id: @user.team_id,
        has_custom_permission: @user.has_permission?("special_action"),
        action: action.to_s,
        resource_id: resource.id,
        resource_name: resource.name,
        resource_classification: resource.classification,
        resource_department: resource.department,
        resource_team_id: resource.team_id,
        same_department: resource.same_department?(@user),
        same_team: resource.same_team?(@user)
      }
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
    rule.ruleset = 'custom_adapter'
    rule.description = 'Custom adapter integration example'
    rule.status = 'active'
    rule.save!

    unless rule.active_version
      version = service.save_rule_version(
        rule_id: RULE_ID,
        content: rules_definition,
        created_by: 'system',
        changelog: 'Initial custom adapter example'
      )
      version.activate!
    end
  end

  # Example usage: Demonstrate custom adapter
  def self.simulate_custom_adapter
    setup_rules

    # Create test users with custom attributes
    high_clearance_user = CustomUser.new(
      id: 1,
      email: 'high_clearance@example.com',
      department: 'Engineering',
      security_clearance: 5,
      team_id: 1,
      permissions: ['special_action']
    )

    low_clearance_user = CustomUser.new(
      id: 2,
      email: 'low_clearance@example.com',
      department: 'Marketing',
      security_clearance: 2,
      team_id: 2,
      permissions: []
    )

    team_member = CustomUser.new(
      id: 3,
      email: 'teammate@example.com',
      department: 'Engineering',
      security_clearance: 3,
      team_id: 1,
      permissions: []
    )

    # Create test resources
    classified_resource = CustomResource.new(
      id: 1,
      name: 'Classified Document',
      department: 'Engineering',
      classification: 'classified',
      team_id: 1,
      created_by: 1
    )

    public_resource = CustomResource.new(
      id: 2,
      name: 'Public Document',
      department: 'Marketing',
      classification: 'public',
      team_id: 2,
      created_by: 2
    )

    team_resource = CustomResource.new(
      id: 3,
      name: 'Team Document',
      department: 'Engineering',
      classification: 'internal',
      team_id: 1,
      created_by: 1
    )

    results = []

    # Test high clearance user accessing classified resource
    adapter = CustomAdapter.new(high_clearance_user)
    results << {
      user: high_clearance_user.email,
      clearance: high_clearance_user.security_clearance,
      action: 'view',
      resource: classified_resource.name,
      classification: classified_resource.classification,
      can: adapter.can?(:view, classified_resource),
      adapter: 'custom'
    }

    # Test low clearance user accessing classified resource
    adapter = CustomAdapter.new(low_clearance_user)
    results << {
      user: low_clearance_user.email,
      clearance: low_clearance_user.security_clearance,
      action: 'view',
      resource: classified_resource.name,
      classification: classified_resource.classification,
      can: adapter.can?(:view, classified_resource),
      adapter: 'custom'
    }

    # Test team member collaboration
    adapter = CustomAdapter.new(team_member)
    results << {
      user: team_member.email,
      action: 'collaborate',
      resource: team_resource.name,
      same_team: true,
      can: adapter.can?(:collaborate, team_resource),
      adapter: 'custom'
    }

    # Test public resource access
    adapter = CustomAdapter.new(low_clearance_user)
    results << {
      user: low_clearance_user.email,
      action: 'view',
      resource: public_resource.name,
      classification: public_resource.classification,
      can: adapter.can?(:view, public_resource),
      adapter: 'custom'
    }

    # Test custom permission
    adapter = CustomAdapter.new(high_clearance_user)
    results << {
      user: high_clearance_user.email,
      action: 'special_action',
      resource: classified_resource.name,
      has_permission: high_clearance_user.has_permission?('special_action'),
      can: adapter.can?(:special_action, classified_resource),
      adapter: 'custom'
    }

    # Test authorization exception
    begin
      adapter = CustomAdapter.new(low_clearance_user)
      adapter.authorize!(:view, classified_resource)
      results << {
        user: low_clearance_user.email,
        action: 'view',
        resource: classified_resource.name,
        authorized: true,
        adapter: 'custom'
      }
    rescue => e
      results << {
        user: low_clearance_user.email,
        action: 'view',
        resource: classified_resource.name,
        authorized: false,
        error: e.message,
        adapter: 'custom'
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

