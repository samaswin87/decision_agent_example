# Multi-Stage Workflow Use Case
# Complex approval workflow with multiple decision points
class MultiStageWorkflowUseCase
  class << self
    def setup_rules
      # Stage 1: Initial Triage
      DecisionService.instance.save_rule_version(
        rule_id: 'workflow_stage1_triage',
        content: {
          conditions: {
            any: [
              {
                all: [
                  { fact: 'request_type', operator: 'eq', value: 'emergency' },
                  { fact: 'request_amount', operator: 'lte', value: 10000 }
                ]
              },
              {
                all: [
                  { fact: 'request_type', operator: 'eq', value: 'standard' },
                  { fact: 'request_amount', operator: 'lte', value: 1000 },
                  { fact: 'requester_level', operator: 'gte', value: 3 }
                ]
              }
            ]
          },
          decision: 'auto_approve_stage1',
          priority: 200,
          metadata: {
            stage: 1,
            stage_name: 'initial_triage',
            next_stage: 'complete',
            requires_approval: false,
            auto_approved: true,
            processing_time_hours: 0,
            approvers_required: 0
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Stage 1 - Auto approval for low-risk requests'
      )
      DecisionService.instance.activate_version('workflow_stage1_triage', 1)

      DecisionService.instance.save_rule_version(
        rule_id: 'workflow_stage1_to_stage2',
        content: {
          conditions: {
            any: [
              {
                all: [
                  { fact: 'request_amount', operator: 'gt', value: 1000 },
                  { fact: 'request_amount', operator: 'lte', value: 10000 }
                ]
              },
              {
                all: [
                  { fact: 'request_type', operator: 'eq', value: 'standard' },
                  { fact: 'requester_level', operator: 'lt', value: 3 }
                ]
              }
            ]
          },
          decision: 'proceed_to_stage2',
          priority: 150,
          metadata: {
            stage: 1,
            stage_name: 'initial_triage',
            next_stage: 2,
            requires_approval: true,
            auto_approved: false,
            processing_time_hours: 2,
            approvers_required: 1,
            approver_roles: ['manager']
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Stage 1 - Route to stage 2 for manager approval'
      )
      DecisionService.instance.activate_version('workflow_stage1_to_stage2', 1)

      # Stage 2: Manager Review
      DecisionService.instance.save_rule_version(
        rule_id: 'workflow_stage2_manager',
        content: {
          conditions: {
            all: [
              { fact: 'stage1_approved', operator: 'eq', value: true },
              { fact: 'request_amount', operator: 'lte', value: 10000 },
              { fact: 'risk_score', operator: 'lte', value: 50 }
            ]
          },
          decision: 'manager_approved',
          priority: 200,
          metadata: {
            stage: 2,
            stage_name: 'manager_review',
            next_stage: 'complete',
            requires_approval: false,
            auto_approved: false,
            processing_time_hours: 4,
            approvers_required: 1,
            approval_level: 'manager'
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Stage 2 - Manager approval path'
      )
      DecisionService.instance.activate_version('workflow_stage2_manager', 1)

      DecisionService.instance.save_rule_version(
        rule_id: 'workflow_stage2_to_stage3',
        content: {
          conditions: {
            all: [
              { fact: 'stage1_approved', operator: 'eq', value: true },
              {
                any: [
                  { fact: 'request_amount', operator: 'gt', value: 10000 },
                  { fact: 'risk_score', operator: 'gt', value: 50 }
                ]
              }
            ]
          },
          decision: 'proceed_to_stage3',
          priority: 180,
          metadata: {
            stage: 2,
            stage_name: 'manager_review',
            next_stage: 3,
            requires_approval: true,
            auto_approved: false,
            processing_time_hours: 8,
            approvers_required: 2,
            approver_roles: ['senior_manager', 'director']
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Stage 2 - Route to stage 3 for senior approval'
      )
      DecisionService.instance.activate_version('workflow_stage2_to_stage3', 1)

      # Stage 3: Senior Leadership Review
      DecisionService.instance.save_rule_version(
        rule_id: 'workflow_stage3_leadership',
        content: {
          conditions: {
            all: [
              { fact: 'stage2_approved', operator: 'eq', value: true },
              { fact: 'request_amount', operator: 'lte', value: 50000 },
              { fact: 'compliance_check', operator: 'eq', value: true }
            ]
          },
          decision: 'leadership_approved',
          priority: 200,
          metadata: {
            stage: 3,
            stage_name: 'leadership_review',
            next_stage: 'complete',
            requires_approval: false,
            auto_approved: false,
            processing_time_hours: 24,
            approvers_required: 2,
            approval_level: 'director',
            requires_compliance_sign_off: true
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Stage 3 - Leadership approval path'
      )
      DecisionService.instance.activate_version('workflow_stage3_leadership', 1)

      DecisionService.instance.save_rule_version(
        rule_id: 'workflow_stage3_to_stage4',
        content: {
          conditions: {
            all: [
              { fact: 'stage2_approved', operator: 'eq', value: true },
              {
                any: [
                  { fact: 'request_amount', operator: 'gt', value: 50000 },
                  { fact: 'compliance_check', operator: 'eq', value: false },
                  { fact: 'legal_review_required', operator: 'eq', value: true }
                ]
              }
            ]
          },
          decision: 'proceed_to_stage4',
          priority: 180,
          metadata: {
            stage: 3,
            stage_name: 'leadership_review',
            next_stage: 4,
            requires_approval: true,
            auto_approved: false,
            processing_time_hours: 48,
            approvers_required: 3,
            approver_roles: ['cfo', 'legal', 'ceo']
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Stage 3 - Route to stage 4 for executive approval'
      )
      DecisionService.instance.activate_version('workflow_stage3_to_stage4', 1)

      # Stage 4: Executive Approval
      DecisionService.instance.save_rule_version(
        rule_id: 'workflow_stage4_executive',
        content: {
          conditions: {
            all: [
              { fact: 'stage3_approved', operator: 'eq', value: true },
              { fact: 'legal_review_approved', operator: 'eq', value: true },
              { fact: 'financial_review_approved', operator: 'eq', value: true }
            ]
          },
          decision: 'executive_approved',
          priority: 200,
          metadata: {
            stage: 4,
            stage_name: 'executive_review',
            next_stage: 'complete',
            requires_approval: false,
            auto_approved: false,
            processing_time_hours: 72,
            approvers_required: 3,
            approval_level: 'executive',
            board_notification_required: true
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Stage 4 - Executive approval path'
      )
      DecisionService.instance.activate_version('workflow_stage4_executive', 1)

      # Rejection Rules
      DecisionService.instance.save_rule_version(
        rule_id: 'workflow_rejection',
        content: {
          conditions: {
            any: [
              { fact: 'fraud_detected', operator: 'eq', value: true },
              { fact: 'blacklisted', operator: 'eq', value: true },
              { fact: 'risk_score', operator: 'gte', value: 90 },
              {
                all: [
                  { fact: 'compliance_check', operator: 'eq', value: false },
                  { fact: 'request_amount', operator: 'gt', value: 100000 }
                ]
              }
            ]
          },
          decision: 'rejected',
          priority: 250,
          metadata: {
            stage: 'any',
            stage_name: 'rejection',
            next_stage: 'complete',
            requires_approval: false,
            auto_approved: false,
            processing_time_hours: 0,
            rejection_final: true
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Rejection rule for high-risk requests'
      )
      DecisionService.instance.activate_version('workflow_rejection', 1)

      puts "✓ Multi-stage workflow rules created successfully"
    end

    def evaluate_stage(stage_number, context)
      rule_ids = case stage_number
      when 1
        ['workflow_rejection', 'workflow_stage1_triage', 'workflow_stage1_to_stage2']
      when 2
        ['workflow_rejection', 'workflow_stage2_manager', 'workflow_stage2_to_stage3']
      when 3
        ['workflow_rejection', 'workflow_stage3_leadership', 'workflow_stage3_to_stage4']
      when 4
        ['workflow_rejection', 'workflow_stage4_executive']
      else
        []
      end

      result = DecisionService.instance.evaluate(rule_ids, context)

      # Add workflow metadata
      metadata = result[:metadata] || {}

      result[:workflow] = {
        current_stage: stage_number,
        current_stage_name: metadata['stage_name'],
        next_stage: metadata['next_stage'],
        requires_approval: metadata['requires_approval'],
        approvers_required: metadata['approvers_required'],
        approver_roles: metadata['approver_roles'],
        estimated_processing_hours: metadata['processing_time_hours'],
        is_complete: metadata['next_stage'] == 'complete'
      }

      # Calculate total estimated time if not complete
      unless result[:workflow][:is_complete]
        result[:workflow][:total_estimated_time_hours] = estimate_total_time(context, result)
      end

      result
    end

    def evaluate_complete_workflow(context)
      stages = []
      current_context = context.dup
      current_stage = 1

      # Simulate workflow progression
      loop do
        stage_result = evaluate_stage(current_stage, current_context)
        stages << {
          stage_number: current_stage,
          decision: stage_result[:decision],
          confidence: stage_result[:confidence],
          metadata: stage_result[:metadata],
          workflow: stage_result[:workflow]
        }

        # Update context for next stage
        current_context["stage#{current_stage}_approved".to_sym] = true

        # Check if workflow is complete
        break if stage_result[:workflow][:is_complete]
        break if stage_result[:decision] == 'rejected'

        # Move to next stage
        next_stage = stage_result[:workflow][:next_stage]
        break if next_stage == 'complete' || next_stage.nil?

        current_stage = next_stage.to_i
        break if current_stage > 4 # Safety check
      end

      {
        request_id: context[:request_id],
        stages: stages,
        final_decision: stages.last[:decision],
        total_stages: stages.length,
        total_processing_time_hours: stages.sum { |s| s.dig(:metadata, 'processing_time_hours') || 0 },
        approvers_involved: stages.sum { |s| s.dig(:metadata, 'approvers_required') || 0 }
      }
    end

    private

    def estimate_total_time(context, current_result)
      # Estimate remaining stages based on amount and risk
      amount = context[:request_amount] || 0
      risk = context[:risk_score] || 0
      current_time = current_result.dig(:metadata, 'processing_time_hours') || 0

      additional_time = 0
      if amount > 50000 || risk > 50
        additional_time += 72 # Stage 4
      end
      if amount > 10000 || risk > 50
        additional_time += 24 # Stage 3
      end
      if amount > 1000
        additional_time += 8 # Stage 2
      end

      current_time + additional_time
    end
  end
end
