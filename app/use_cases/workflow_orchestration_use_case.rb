# Workflow Orchestration Use Case
# Demonstrates complex multi-stage decision workflows using DecisionAgent
# Shows how to chain decisions and handle workflow state
class WorkflowOrchestrationUseCase
  RULE_ID_PREFIX = 'workflow_'

  class << self
    def setup_rules
      service = DecisionService.instance

      # Stage 1: Initial Screening
      setup_stage_rule('initial_screening', {
        rules: [
          {
            id: "basic_requirements",
            if: {
              all: [
                { field: "age", op: "gte", value: 18 },
                { field: "age", op: "lte", value: 75 },
                { field: "has_valid_id", op: "eq", value: true }
              ]
            },
            then: {
              decision: "pass_initial",
              weight: 1.0,
              reason: "Meets basic requirements",
              metadata: { stage: 1, next_stage: "credit_check" }
            }
          },
          {
            id: "fail_initial",
            if: {
              any: [
                { field: "age", op: "lt", value: 18 },
                { field: "age", op: "gt", value: 75 },
                { field: "has_valid_id", op: "eq", value: false }
              ]
            },
            then: {
              decision: "fail_initial",
              weight: 1.0,
              reason: "Does not meet basic requirements",
              metadata: { stage: 1, workflow_status: "rejected" }
            }
          }
        ]
      })

      # Stage 2: Credit Check
      setup_stage_rule('credit_check', {
        rules: [
          {
            id: "excellent_credit",
            if: {
              all: [
                { field: "credit_score", op: "gte", value: 750 },
                { field: "credit_history_years", op: "gte", value: 5 }
              ]
            },
            then: {
              decision: "pass_credit",
              weight: 1.0,
              reason: "Excellent credit history",
              metadata: { stage: 2, next_stage: "income_verification", fast_track: true }
            }
          },
          {
            id: "good_credit",
            if: {
              all: [
                { field: "credit_score", op: "gte", value: 650 },
                { field: "credit_score", op: "lt", value: 750 }
              ]
            },
            then: {
              decision: "pass_credit",
              weight: 0.8,
              reason: "Good credit history",
              metadata: { stage: 2, next_stage: "income_verification" }
            }
          },
          {
            id: "fail_credit",
            if: {
              field: "credit_score",
              op: "lt",
              value: 650
            },
            then: {
              decision: "fail_credit",
              weight: 1.0,
              reason: "Credit score too low",
              metadata: { stage: 2, workflow_status: "rejected" }
            }
          }
        ]
      })

      # Stage 3: Income Verification
      setup_stage_rule('income_verification', {
        rules: [
          {
            id: "high_income",
            if: {
              all: [
                { field: "annual_income", op: "gte", value: 75000 },
                { field: "employment_status", op: "eq", value: "employed" },
                { field: "employment_years", op: "gte", value: 2 }
              ]
            },
            then: {
              decision: "pass_income",
              weight: 1.0,
              reason: "High income verified",
              metadata: { stage: 3, next_stage: "final_approval", auto_approve: true }
            }
          },
          {
            id: "medium_income",
            if: {
              all: [
                { field: "annual_income", op: "gte", value: 40000 },
                { field: "annual_income", op: "lt", value: 75000 },
                { field: "employment_status", op: "eq", value: "employed" }
              ]
            },
            then: {
              decision: "pass_income",
              weight: 0.7,
              reason: "Medium income verified",
              metadata: { stage: 3, next_stage: "manual_review" }
            }
          },
          {
            id: "fail_income",
            if: {
              field: "annual_income",
              op: "lt",
              value: 40000
            },
            then: {
              decision: "fail_income",
              weight: 1.0,
              reason: "Income too low",
              metadata: { stage: 3, workflow_status: "rejected" }
            }
          }
        ]
      })

      # Stage 4: Final Approval
      setup_stage_rule('final_approval', {
        rules: [
          {
            id: "auto_approve",
            if: {
              all: [
                { field: "auto_approve", op: "eq", value: true },
                { field: "debt_to_income", op: "lte", value: 0.4 }
              ]
            },
            then: {
              decision: "approved",
              weight: 1.0,
              reason: "Auto-approved based on criteria",
              metadata: { stage: 4, workflow_status: "approved" }
            }
          },
          {
            id: "manual_approval",
            if: {
              field: "manual_review",
              op: "eq",
              value: true
            },
            then: {
              decision: "pending_review",
              weight: 0.8,
              reason: "Requires manual review",
              metadata: { stage: 4, workflow_status: "pending" }
            }
          }
        ]
      })

      puts "✓ Workflow orchestration rules created successfully"
    end

    # Execute workflow with all stages
    def execute_workflow(context)
      setup_rules
      service = DecisionService.instance

      workflow_state = {
        current_stage: 1,
        context: context,
        history: [],
        status: "in_progress"
      }

      stages = [
        { id: 'initial_screening', name: 'Initial Screening' },
        { id: 'credit_check', name: 'Credit Check' },
        { id: 'income_verification', name: 'Income Verification' },
        { id: 'final_approval', name: 'Final Approval' }
      ]

      stages.each_with_index do |stage, index|
        rule_id = "#{RULE_ID_PREFIX}#{stage[:id]}"
        
        # Evaluate current stage
        result = service.evaluate(
          rule_id: rule_id,
          context: workflow_state[:context]
        )

        # Record stage result
        stage_result = {
          stage: index + 1,
          stage_name: stage[:name],
          decision: result[:decision],
          confidence: result[:confidence],
          reason: result[:explanations]&.first,
          metadata: result[:evaluations]&.first&.dig(:metadata) || {}
        }

        workflow_state[:history] << stage_result

        # Check if workflow should continue
        if result[:decision]&.start_with?('fail_') || result[:decision] == 'rejected'
          workflow_state[:status] = 'rejected'
          workflow_state[:rejection_stage] = stage[:name]
          break
        elsif result[:decision] == 'approved'
          workflow_state[:status] = 'approved'
          break
        elsif result[:decision] == 'pending_review'
          workflow_state[:status] = 'pending'
          break
        end

        # Update context for next stage if needed
        metadata = stage_result[:metadata]
        if metadata[:next_stage]
          workflow_state[:context] = workflow_state[:context].merge(
            fast_track: metadata[:fast_track] || false,
            auto_approve: metadata[:auto_approve] || false,
            manual_review: metadata[:next_stage] == 'manual_review'
          )
        end

        workflow_state[:current_stage] = index + 2
      end

      {
        workflow_id: "workflow_#{Time.now.to_i}",
        status: workflow_state[:status],
        stages_completed: workflow_state[:history].length,
        current_stage: workflow_state[:current_stage],
        history: workflow_state[:history],
        final_decision: workflow_state[:history].last&.dig(:decision),
        context: workflow_state[:context]
      }
    end

    # Execute workflow with early exit conditions
    def execute_workflow_with_early_exit(context)
      setup_rules
      service = DecisionService.instance

      workflow_state = {
        context: context,
        history: [],
        status: "in_progress"
      }

      # Stage 1: Initial Screening
      result1 = service.evaluate(
        rule_id: "#{RULE_ID_PREFIX}initial_screening",
        context: context
      )

      if result1[:decision] == 'fail_initial'
        return {
          status: 'rejected',
          reason: 'Failed initial screening',
          stage: 1,
          history: [{ stage: 1, decision: result1[:decision] }]
        }
      end

      workflow_state[:history] << { stage: 1, decision: result1[:decision] }

      # Stage 2: Credit Check
      result2 = service.evaluate(
        rule_id: "#{RULE_ID_PREFIX}credit_check",
        context: context
      )

      if result2[:decision] == 'fail_credit'
        return {
          status: 'rejected',
          reason: 'Failed credit check',
          stage: 2,
          history: workflow_state[:history] + [{ stage: 2, decision: result2[:decision] }]
        }
      end

      workflow_state[:history] << { stage: 2, decision: result2[:decision] }

      # Fast track check
      fast_track = result2[:evaluations]&.first&.dig(:metadata, :fast_track)
      if fast_track
        # Skip to final approval
        result4 = service.evaluate(
          rule_id: "#{RULE_ID_PREFIX}final_approval",
          context: context.merge(auto_approve: true)
        )
        workflow_state[:history] << { stage: 3, decision: 'skipped', reason: 'Fast track' }
        workflow_state[:history] << { stage: 4, decision: result4[:decision] }
        workflow_state[:status] = result4[:decision] == 'approved' ? 'approved' : 'pending'
      else
        # Continue with income verification
        result3 = service.evaluate(
          rule_id: "#{RULE_ID_PREFIX}income_verification",
          context: context
        )
        workflow_state[:history] << { stage: 3, decision: result3[:decision] }

        if result3[:decision] == 'fail_income'
          workflow_state[:status] = 'rejected'
        else
          result4 = service.evaluate(
            rule_id: "#{RULE_ID_PREFIX}final_approval",
            context: context.merge(
              auto_approve: result3[:evaluations]&.first&.dig(:metadata, :auto_approve) || false,
              manual_review: result3[:evaluations]&.first&.dig(:metadata, :next_stage) == 'manual_review'
            )
          )
          workflow_state[:history] << { stage: 4, decision: result4[:decision] }
          workflow_state[:status] = result4[:decision] == 'approved' ? 'approved' : 'pending'
        end
      end

      {
        status: workflow_state[:status],
        history: workflow_state[:history],
        fast_track_used: fast_track || false
      }
    end

    private

    def setup_stage_rule(stage_id, content)
      service = DecisionService.instance
      rule_id = "#{RULE_ID_PREFIX}#{stage_id}"

      rule = Rule.find_or_initialize_by(rule_id: rule_id)
      rule.ruleset = 'workflow_orchestration'
      rule.description = "Workflow stage: #{stage_id}"
      rule.status = 'active'
      rule.save!

      unless rule.active_version
        version = service.save_rule_version(
          rule_id: rule_id,
          content: {
            version: "1.0",
            ruleset: "workflow_orchestration",
            description: "Workflow stage: #{stage_id}",
            **content
          },
          created_by: 'system',
          changelog: "Initial workflow stage: #{stage_id}"
        )
        version.activate!
      end
    end
  end
end

