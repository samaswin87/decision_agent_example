# RBAC (Role-Based Access Control) Use Case
# Demonstrates decision-making based on user roles and permissions
class RbacUseCase
  RULE_ID = 'rbac_access_control'

  # Define roles and their permissions
  ROLES = {
    'admin' => {
      name: 'Administrator',
      permissions: ['view_all', 'edit_all', 'delete_all', 'approve_all', 'export_data', 'batch_process'],
      description: 'Full access to all features'
    },
    'manager' => {
      name: 'Manager',
      permissions: ['view_all', 'edit_own', 'approve_limited', 'export_data', 'batch_process'],
      description: 'Can view all, edit own, approve limited amounts'
    },
    'analyst' => {
      name: 'Analyst',
      permissions: ['view_all', 'export_data', 'batch_process'],
      description: 'Read-only access with export and batch processing'
    },
    'viewer' => {
      name: 'Viewer',
      permissions: ['view_limited'],
      description: 'Limited view-only access'
    },
    'operator' => {
      name: 'Operator',
      permissions: ['view_own', 'edit_own', 'batch_process'],
      description: 'Can view and edit own records, run batch processes'
    }
  }.freeze

  def self.rules_definition
    {
      version: "1.0",
      ruleset: "rbac_access_control",
      description: "Role-based access control rules for decision making",
      rules: [
        {
          id: "admin_full_access",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "admin" },
              {
                any: [
                  { field: "action", op: "eq", value: "view" },
                  { field: "action", op: "eq", value: "edit" },
                  { field: "action", op: "eq", value: "delete" },
                  { field: "action", op: "eq", value: "approve" },
                  { field: "action", op: "eq", value: "export" },
                  { field: "action", op: "eq", value: "batch" }
                ]
              }
            ]
          },
          then: {
            decision: "allowed",
            weight: 1.0,
            reason: "Admin has full access to all actions",
            metadata: {
              access_level: "full",
              requires_approval: false,
              audit_required: true
            }
          }
        },
        {
          id: "manager_web_ui_access",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "manager" },
              { field: "resource_type", op: "eq", value: "web_ui" },
              {
                any: [
                  { field: "action", op: "eq", value: "view" },
                  { field: "action", op: "eq", value: "edit" },
                  { field: "action", op: "eq", value: "export" },
                  { field: "action", op: "eq", value: "batch" }
                ]
              }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.95,
            reason: "Manager can access web UI for view, edit, export, and batch actions",
            metadata: {
              access_level: "web_ui",
              audit_required: true
            }
          }
        },
        {
          id: "manager_approval_limited",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "manager" },
              { field: "action", op: "eq", value: "approve" },
              { field: "amount", op: "lte", value: 10000 }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.9,
            reason: "Manager can approve amounts up to $10,000",
            metadata: {
              access_level: "limited",
              max_amount: 10000,
              requires_approval: false,
              audit_required: true
            }
          }
        },
        {
          id: "manager_approval_high",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "manager" },
              { field: "action", op: "eq", value: "approve" },
              { field: "amount", op: "gt", value: 10000 }
            ]
          },
          then: {
            decision: "requires_approval",
            weight: 0.8,
            reason: "Manager requires admin approval for amounts over $10,000",
            metadata: {
              access_level: "limited",
              requires_approval: true,
              approver_role: "admin",
              audit_required: true
            }
          }
        },
        {
          id: "analyst_view_export",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "analyst" },
              {
                any: [
                  { field: "action", op: "eq", value: "view" },
                  { field: "action", op: "eq", value: "export" },
                  { field: "action", op: "eq", value: "batch" }
                ]
              }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.9,
            reason: "Analyst can view, export, and run batch processes",
            metadata: {
              access_level: "read_only",
              can_export: true,
              can_batch: true,
              audit_required: true
            }
          }
        },
        {
          id: "analyst_web_ui_access",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "analyst" },
              { field: "resource_type", op: "eq", value: "web_ui" },
              {
                any: [
                  { field: "action", op: "eq", value: "view" },
                  { field: "action", op: "eq", value: "export" },
                  { field: "action", op: "eq", value: "batch" }
                ]
              }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.95,
            reason: "Analyst can access web UI for view, export, and batch actions",
            metadata: {
              access_level: "web_ui_readonly",
              audit_required: true
            }
          }
        },
        {
          id: "analyst_edit_denied",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "analyst" },
              {
                any: [
                  { field: "action", op: "eq", value: "edit" },
                  { field: "action", op: "eq", value: "delete" },
                  { field: "action", op: "eq", value: "approve" }
                ]
              }
            ]
          },
          then: {
            decision: "denied",
            weight: 1.0,
            reason: "Analyst role does not have edit/delete/approve permissions",
            metadata: {
              access_level: "read_only",
              required_role: "manager",
              audit_required: true
            }
          }
        },
        {
          id: "viewer_web_ui_access",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "viewer" },
              { field: "resource_type", op: "eq", value: "web_ui" },
              { field: "action", op: "eq", value: "view" }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.9,
            reason: "Viewer can view web UI",
            metadata: {
              access_level: "web_ui_view_only",
              audit_required: false
            }
          }
        },
        {
          id: "viewer_limited_access",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "viewer" },
              { field: "action", op: "eq", value: "view" },
              {
                any: [
                  { field: "resource_type", op: "eq", value: "public" },
                  { field: "resource_type", op: "eq", value: "shared" }
                ]
              }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.8,
            reason: "Viewer can view public and shared resources",
            metadata: {
              access_level: "view_only",
              allowed_resources: ["public", "shared"],
              audit_required: false
            }
          }
        },
        {
          id: "viewer_denied",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "viewer" },
              {
                any: [
                  { field: "action", op: "eq", value: "edit" },
                  { field: "action", op: "eq", value: "delete" },
                  { field: "action", op: "eq", value: "approve" },
                  { field: "action", op: "eq", value: "export" },
                  { field: "action", op: "eq", value: "batch" }
                ]
              }
            ]
          },
          then: {
            decision: "denied",
            weight: 1.0,
            reason: "Viewer role only has view permissions",
            metadata: {
              access_level: "view_only",
              audit_required: false
            }
          }
        },
        {
          id: "operator_web_ui_access",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "operator" },
              { field: "resource_type", op: "eq", value: "web_ui" },
              {
                any: [
                  { field: "action", op: "eq", value: "view" },
                  { field: "action", op: "eq", value: "edit" },
                  { field: "action", op: "eq", value: "batch" }
                ]
              },
              { field: "is_own_resource", op: "eq", value: true }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.95,
            reason: "Operator can access web UI for view, edit, and batch actions on own resources",
            metadata: {
              access_level: "web_ui_own",
              audit_required: true
            }
          }
        },
        {
          id: "operator_own_resources",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "operator" },
              {
                any: [
                  { field: "action", op: "eq", value: "view" },
                  { field: "action", op: "eq", value: "edit" },
                  { field: "action", op: "eq", value: "batch" }
                ]
              },
              { field: "is_own_resource", op: "eq", value: true }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.9,
            reason: "Operator can view, edit, and batch process own resources",
            metadata: {
              access_level: "own_resources",
              can_batch: true,
              audit_required: true
            }
          }
        },
        {
          id: "operator_others_denied",
          if: {
            all: [
              { field: "user_role", op: "eq", value: "operator" },
              { field: "is_own_resource", op: "neq", value: true }
            ]
          },
          then: {
            decision: "denied",
            weight: 1.0,
            reason: "Operator can only access own resources",
            metadata: {
              access_level: "own_resources",
              audit_required: true
            }
          }
        },
        {
          id: "batch_process_allowed",
          if: {
            all: [
              { field: "action", op: "eq", value: "batch" },
              {
                any: [
                  { field: "user_role", op: "eq", value: "admin" },
                  { field: "user_role", op: "eq", value: "manager" },
                  { field: "user_role", op: "eq", value: "analyst" },
                  { field: "user_role", op: "eq", value: "operator" }
                ]
              }
            ]
          },
          then: {
            decision: "allowed",
            weight: 0.95,
            reason: "Batch processing allowed for admin, manager, analyst, and operator roles",
            metadata: {
              access_level: "batch_allowed",
              max_batch_size: 10000,
              audit_required: true
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
              access_level: "none",
              audit_required: true
            }
          }
        }
      ]
    }
  end

  def self.evaluate(context)
    service = DecisionService.instance
    result = service.evaluate(
      rule_id: RULE_ID,
      context: context
    )

    format_result(result, context)
  end

  def self.evaluate_batch(contexts, parallel: false)
    setup_rules

    start_time = Time.current

    results = if parallel
      contexts.map do |ctx|
        Thread.new { evaluate(ctx) }
      end.map(&:value)
    else
      contexts.map { |ctx| evaluate(ctx) }
    end

    end_time = Time.current
    duration = end_time - start_time

    # Calculate statistics
    allowed_count = results.count { |r| r[:decision] == 'allowed' }
    denied_count = results.count { |r| r[:decision] == 'denied' }
    requires_approval_count = results.count { |r| r[:decision] == 'requires_approval' }

    # Group by role
    role_stats = results.group_by { |r| r[:context][:user_role] }.transform_values do |role_results|
      {
        total: role_results.size,
        allowed: role_results.count { |r| r[:decision] == 'allowed' },
        denied: role_results.count { |r| r[:decision] == 'denied' },
        requires_approval: role_results.count { |r| r[:decision] == 'requires_approval' }
      }
    end

    {
      results: results,
      statistics: {
        total_evaluations: contexts.size,
        allowed: allowed_count,
        denied: denied_count,
        requires_approval: requires_approval_count,
        allowed_percentage: ((allowed_count.to_f / contexts.size) * 100).round(2),
        denied_percentage: ((denied_count.to_f / contexts.size) * 100).round(2),
        role_statistics: role_stats
      },
      performance: {
        duration_seconds: duration.round(3),
        average_per_evaluation_ms: ((duration / contexts.size) * 1000).round(2),
        evaluations_per_second: (contexts.size / duration).round(2),
        parallel: parallel,
        started_at: start_time,
        completed_at: end_time
      }
    }
  end

  def self.setup_rules
    service = DecisionService.instance

    rule = Rule.find_or_initialize_by(rule_id: RULE_ID)
    rule.ruleset = 'rbac_access_control'
    rule.description = 'Role-based access control rules'
    rule.status = 'active'
    rule.save!

    # Always create a new version to ensure rules are up to date
    # This fixes any issues with stale database versions
    version = service.save_rule_version(
      rule_id: RULE_ID,
      content: rules_definition,
      created_by: 'system',
      changelog: rule.active_version ? 'Updated RBAC rules version' : 'Initial RBAC rules version'
    )
    version.activate!
  end

  def self.generate_test_contexts(count: 100, role_distribution: nil)
    # Default role distribution
    distribution = role_distribution || {
      'admin' => 0.1,
      'manager' => 0.2,
      'analyst' => 0.3,
      'viewer' => 0.2,
      'operator' => 0.2
    }

    actions = ['view', 'edit', 'delete', 'approve', 'export', 'batch']
    resource_types = ['public', 'shared', 'private', 'confidential']
    amounts = [100, 500, 1000, 5000, 10000, 15000, 25000, 50000]

    contexts = []
    count.times do |i|
      # Select role based on distribution
      rand_val = rand
      cumulative = 0.0
      selected_role = distribution.keys.first
      
      distribution.each do |role, prob|
        cumulative += prob
        if rand_val <= cumulative
          selected_role = role
          break
        end
      end

      action = actions.sample
      context = {
        user_id: "user_#{i + 1}",
        user_role: selected_role,
        action: action,
        resource_type: resource_types.sample,
        resource_owner: "user_#{rand(1..count)}",
        timestamp: Time.current
      }

      # Add amount for approval actions
      if action == 'approve'
        context[:amount] = amounts.sample
      end

      # For operator role, set is_own_resource flag
      if selected_role == 'operator'
        # 70% chance it's their own resource
        context[:is_own_resource] = rand < 0.7
        context[:resource_owner] = context[:is_own_resource] ? context[:user_id] : "other"
      else
        context[:is_own_resource] = true  # Default for other roles
      end

      contexts << context
    end

    contexts
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

