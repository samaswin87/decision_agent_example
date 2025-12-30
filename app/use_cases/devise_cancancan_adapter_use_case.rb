# Devise + CanCanCan Adapter Use Case
# Demonstrates how to integrate DecisionAgent with Devise authentication and CanCanCan authorization
# This example shows how to use DecisionAgent rules with Devise users and CanCanCan abilities
class DeviseCancancanAdapterUseCase
  RULE_ID = 'devise_cancancan_adapter_example'

  # Example: Simulated Devise User model
  class DeviseUser
    attr_reader :id, :email, :role, :confirmed_at, :organization_id

    def initialize(id:, email:, role:, confirmed_at: Time.current, organization_id: nil)
      @id = id
      @email = email
      @role = role
      @confirmed_at = confirmed_at
      @organization_id = organization_id
    end

    def confirmed?
      !confirmed_at.nil?
    end

    def admin?
      role == 'admin'
    end

    def manager?
      role == 'manager'
    end

    def user?
      role == 'user'
    end
  end

  # Example: Simulated Article model
  class Article
    attr_reader :id, :title, :user_id, :organization_id, :published, :created_at

    def initialize(id:, title:, user_id:, organization_id: nil, published: false, created_at: Time.current)
      @id = id
      @title = title
      @user_id = user_id
      @organization_id = organization_id
      @published = published
      @created_at = created_at
    end

    def published?
      published
    end

    def author?(user)
      user_id == user.id
    end
  end

  def self.rules_definition
    {
      version: "1.0",
      ruleset: "devise_cancancan_adapter",
      description: "Devise + CanCanCan adapter integration rules for authorization decisions",
      rules: [
        {
          id: "admin_all_actions",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "admin" },
              { field: "user_confirmed", op: "eq", value: true }
            ]
          },
          then: {
            decision: "allowed",
            weight: 1.0,
            reason: "Admin can perform all actions on all resources",
            metadata: {
              cancan_actions: ["read", "create", "update", "destroy", "manage"],
              scope: "all"
            }
          }
        },
        {
          id: "manager_manage_organization",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "manager" },
              { field: "user_confirmed", op: "eq", value: true },
              { field: "same_organization", op: "eq", value: true },
              {
                any: [
                  { field: "action", op: "eq", value: "read" },
                  { field: "action", op: "eq", value: "create" },
                  { field: "action", op: "eq", value: "update" }
                ]
              }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.9,
            reason: "Manager can read, create, and update resources in their organization",
            metadata: {
              cancan_actions: ["read", "create", "update"],
              scope: "organization"
            }
          }
        },
        {
          id: "user_manage_own",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "user" },
              { field: "user_confirmed", op: "eq", value: true },
              { field: "is_author", op: "eq", value: true },
              {
                any: [
                  { field: "action", op: "eq", value: "read" },
                  { field: "action", op: "eq", value: "update" },
                  { field: "action", op: "eq", value: "destroy" }
                ]
              }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.8,
            reason: "User can manage their own resources",
            metadata: {
              cancan_actions: ["read", "update", "destroy"],
              scope: "own"
            }
          }
        },
        {
          id: "user_read_published",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "user" },
              { field: "user_confirmed", op: "eq", value: true },
              { field: "action", op: "eq", value: "read" },
              { field: "resource_published", op: "eq", value: true }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.7,
            reason: "User can read published resources",
            metadata: {
              cancan_actions: ["read"],
              scope: "published"
            }
          }
        },
        {
          id: "unconfirmed_user_denied",
          if: {
            all: [
              { field: "user_confirmed", op: "eq", value: false }
            ]
          },
          then: {
            decision: "denied",
            weight: 1.0,
            reason: "Unconfirmed users cannot perform actions",
            metadata: {
              cancan_actions: [],
              requires_confirmation: true
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
              cancan_actions: []
            }
          }
        }
      ]
    }
  end

  # Simulated CanCanCan Ability class that uses DecisionAgent
  class Ability
    def initialize(user)
      @user = user
    end

    def can?(action, resource)
      evaluate_ability(action, resource)
    end

    def cannot?(action, resource)
      !can?(action, resource)
    end

    private

    def evaluate_ability(action, resource)
      context = build_context(action, resource)
      result = DeviseCancancanAdapterUseCase.evaluate(context)
      result[:decision] == 'allowed'
    end

    def build_context(action, resource)
      {
        user_id: @user.id,
        user_role: @user.role,
        user_email: @user.email,
        user_confirmed: @user.confirmed?,
        action: action.to_s,
        resource_type: resource.class.name.downcase,
        resource_id: resource.id,
        is_author: resource.respond_to?(:author?) ? resource.author?(@user) : false,
        same_organization: resource.respond_to?(:organization_id) && 
                          @user.organization_id && 
                          resource.organization_id == @user.organization_id,
        resource_published: resource.respond_to?(:published?) ? resource.published? : false,
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
    rule.ruleset = 'devise_cancancan_adapter'
    rule.description = 'Devise + CanCanCan adapter integration example'
    rule.status = 'active'
    rule.save!

    unless rule.active_version
      version = service.save_rule_version(
        rule_id: RULE_ID,
        content: rules_definition,
        created_by: 'system',
        changelog: 'Initial Devise + CanCanCan adapter example'
      )
      version.activate!
    end
  end

  # Example usage: Simulate CanCanCan ability checks
  def self.simulate_cancancan_checks
    setup_rules

    # Create test users (Devise-style)
    admin = DeviseUser.new(id: 1, email: 'admin@example.com', role: 'admin', confirmed_at: Time.current, organization_id: 1)
    manager = DeviseUser.new(id: 2, email: 'manager@example.com', role: 'manager', confirmed_at: Time.current, organization_id: 1)
    user1 = DeviseUser.new(id: 3, email: 'user1@example.com', role: 'user', confirmed_at: Time.current, organization_id: 1)
    unconfirmed_user = DeviseUser.new(id: 4, email: 'unconfirmed@example.com', role: 'user', confirmed_at: nil, organization_id: 1)

    # Create test articles
    article1 = Article.new(id: 1, title: 'Article 1', user_id: 3, organization_id: 1, published: false)
    article2 = Article.new(id: 2, title: 'Article 2', user_id: 3, organization_id: 1, published: true)
    article3 = Article.new(id: 3, title: 'Article 3', user_id: 4, organization_id: 2, published: true)

    results = []

    # Test admin abilities
    ability = Ability.new(admin)
    results << {
      user: admin.email,
      role: admin.role,
      action: 'manage',
      resource: article1.title,
      can: ability.can?(:manage, article1)
    }

    # Test manager abilities
    ability = Ability.new(manager)
    results << {
      user: manager.email,
      role: manager.role,
      action: 'update',
      resource: article1.title,
      can: ability.can?(:update, article1),
      same_organization: true
    }

    # Test user own article
    ability = Ability.new(user1)
    results << {
      user: user1.email,
      role: user1.role,
      action: 'update',
      resource: article1.title,
      can: ability.can?(:update, article1),
      is_author: true
    }

    # Test user published article
    ability = Ability.new(user1)
    results << {
      user: user1.email,
      role: user1.role,
      action: 'read',
      resource: article2.title,
      can: ability.can?(:read, article2),
      published: true
    }

    # Test unconfirmed user
    ability = Ability.new(unconfirmed_user)
    results << {
      user: unconfirmed_user.email,
      role: unconfirmed_user.role,
      action: 'read',
      resource: article2.title,
      can: ability.can?(:read, article2),
      confirmed: false
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

