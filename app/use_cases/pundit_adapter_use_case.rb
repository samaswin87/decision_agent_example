# Pundit Adapter Use Case
# Demonstrates how to integrate DecisionAgent with Pundit authorization
# This example shows how to use DecisionAgent rules with Pundit policies
class PunditAdapterUseCase
  RULE_ID = 'pundit_adapter_example'

  # Example: Simulated Pundit User model
  class PunditUser
    attr_reader :id, :email, :role, :organization_id

    def initialize(id:, email:, role:, organization_id: nil)
      @id = id
      @email = email
      @role = role
      @organization_id = organization_id
    end

    def admin?
      role == 'admin'
    end

    def manager?
      role == 'manager'
    end

    def member?
      role == 'member'
    end
  end

  # Example: Simulated Resource model
  class Resource
    attr_reader :id, :name, :organization_id, :owner_id, :visibility

    def initialize(id:, name:, organization_id:, owner_id:, visibility: 'private')
      @id = id
      @name = name
      @organization_id = organization_id
      @owner_id = owner_id
      @visibility = visibility
    end

    def public?
      visibility == 'public'
    end

    def private?
      visibility == 'private'
    end
  end

  def self.rules_definition
    {
      version: "1.0",
      ruleset: "pundit_adapter",
      description: "Pundit adapter integration rules for authorization decisions",
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
            reason: "Admin has full access to all resources",
            metadata: {
              pundit_action: "all",
              scope: "all"
            }
          }
        },
        {
          id: "manager_organization_access",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "manager" },
              { field: "same_organization", op: "eq", value: true }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.9,
            reason: "Manager can access resources in their organization",
            metadata: {
              pundit_action: ["show", "update", "index"],
              scope: "organization"
            }
          }
        },
        {
          id: "member_own_resources",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "member" },
              { field: "is_owner", op: "eq", value: true }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.8,
            reason: "Member can access their own resources",
            metadata: {
              pundit_action: ["show", "update"],
              scope: "own"
            }
          }
        },
        {
          id: "member_public_resources",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "member" },
              { field: "resource_visibility", op: "eq", value: "public" },
              { field: "same_organization", op: "eq", value: true }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.7,
            reason: "Member can view public resources in their organization",
            metadata: {
              pundit_action: ["show"],
              scope: "organization_public"
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
              pundit_action: "none"
            }
          }
        }
      ]
    }
  end

  # Simulated Pundit Policy class that uses DecisionAgent
  class ResourcePolicy
    def initialize(user, resource)
      @user = user
      @resource = resource
    end

    def show?
      evaluate_permission(action: 'show')
    end

    def update?
      evaluate_permission(action: 'update')
    end

    def destroy?
      evaluate_permission(action: 'destroy')
    end

    def index?
      evaluate_permission(action: 'index')
    end

    private

    def evaluate_permission(action:)
      context = build_context(action)
      result = PunditAdapterUseCase.evaluate(context)
      result[:decision] == 'allowed'
    end

    def build_context(action)
      {
        user_id: @user.id,
        user_role: @user.role,
        user_email: @user.email,
        resource_id: @resource.id,
        resource_name: @resource.name,
        resource_visibility: @resource.visibility,
        action: action,
        is_owner: @resource.owner_id == @user.id,
        same_organization: @resource.organization_id == @user.organization_id,
        organization_id: @user.organization_id
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
    rule.ruleset = 'pundit_adapter'
    rule.description = 'Pundit adapter integration example'
    rule.status = 'active'
    rule.save!

    unless rule.active_version
      version = service.save_rule_version(
        rule_id: RULE_ID,
        content: rules_definition,
        created_by: 'system',
        changelog: 'Initial Pundit adapter example'
      )
      version.activate!
    end
  end

  # Example usage: Simulate Pundit authorization checks
  def self.simulate_pundit_checks
    setup_rules

    # Create test users
    admin = PunditUser.new(id: 1, email: 'admin@example.com', role: 'admin', organization_id: 1)
    manager = PunditUser.new(id: 2, email: 'manager@example.com', role: 'manager', organization_id: 1)
    member1 = PunditUser.new(id: 3, email: 'member1@example.com', role: 'member', organization_id: 1)
    member2 = PunditUser.new(id: 4, email: 'member2@example.com', role: 'member', organization_id: 2)

    # Create test resources
    resource1 = Resource.new(id: 1, name: 'Resource 1', organization_id: 1, owner_id: 3, visibility: 'private')
    resource2 = Resource.new(id: 2, name: 'Resource 2', organization_id: 1, owner_id: 3, visibility: 'public')
    resource3 = Resource.new(id: 3, name: 'Resource 3', organization_id: 2, owner_id: 4, visibility: 'private')

    results = []

    # Test admin access
    policy = ResourcePolicy.new(admin, resource1)
    results << {
      user: admin.email,
      resource: resource1.name,
      action: 'show',
      allowed: policy.show?,
      role: admin.role
    }

    # Test manager access
    policy = ResourcePolicy.new(manager, resource1)
    results << {
      user: manager.email,
      resource: resource1.name,
      action: 'update',
      allowed: policy.update?,
      role: manager.role
    }

    # Test member own resource
    policy = ResourcePolicy.new(member1, resource1)
    results << {
      user: member1.email,
      resource: resource1.name,
      action: 'show',
      allowed: policy.show?,
      role: member1.role,
      is_owner: true
    }

    # Test member public resource
    policy = ResourcePolicy.new(member1, resource2)
    results << {
      user: member1.email,
      resource: resource2.name,
      action: 'show',
      allowed: policy.show?,
      role: member1.role,
      visibility: 'public'
    }

    # Test member cross-organization
    policy = ResourcePolicy.new(member1, resource3)
    results << {
      user: member1.email,
      resource: resource3.name,
      action: 'show',
      allowed: policy.show?,
      role: member1.role,
      cross_organization: true
    }

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

