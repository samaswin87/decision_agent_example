# UI Dashboard Use Case
# Demonstrates DecisionAgent with real-time UI updates, visualizations, and interactive decision flows
# This use case showcases how to integrate decision_agent with web UI for real-time monitoring
class UiDashboardUseCase
  RULE_ID = 'ui_customer_onboarding'

  # Multi-step onboarding decision flow with UI visualization
  def self.rules_definition
    {
      version: "1.0",
      ruleset: "customer_onboarding",
      description: "Interactive customer onboarding with real-time UI feedback",
      rules: [
        {
          id: "instant_approval",
          if: {
            all: [
              { field: "credit_score", op: "gte", value: 750 },
              { field: "annual_income", op: "gte", value: 100000 },
              { field: "employment_years", op: "gte", value: 3 },
              { field: "existing_customer", op: "eq", value: true }
            ]
          },
          then: {
            decision: "instant_approval",
            weight: 1.0,
            reason: "Premium customer - instant approval",
            ui_metadata: {
              status_color: "green",
              icon: "check_circle",
              next_step: "account_setup",
              estimated_time: "2 minutes",
              benefits: ["No documentation required", "Priority support", "Premium features unlocked"]
            }
          }
        },
        {
          id: "fast_track_approval",
          if: {
            all: [
              { field: "credit_score", op: "gte", value: 700 },
              { field: "annual_income", op: "gte", value: 60000 },
              { field: "fraud_risk_score", op: "lte", value: 20 }
            ]
          },
          then: {
            decision: "fast_track",
            weight: 0.9,
            reason: "Fast track approval - minimal verification needed",
            ui_metadata: {
              status_color: "blue",
              icon: "fast_forward",
              next_step: "quick_verification",
              estimated_time: "5 minutes",
              required_docs: ["ID verification", "Address proof"],
              benefits: ["Quick approval", "Standard features"]
            }
          }
        },
        {
          id: "standard_review",
          if: {
            all: [
              { field: "credit_score", op: "gte", value: 650 },
              { field: "annual_income", op: "gte", value: 40000 },
              { field: "fraud_risk_score", op: "lte", value: 40 }
            ]
          },
          then: {
            decision: "standard_review",
            weight: 0.7,
            reason: "Standard review process required",
            ui_metadata: {
              status_color: "yellow",
              icon: "pending",
              next_step: "document_upload",
              estimated_time: "24-48 hours",
              required_docs: ["ID verification", "Address proof", "Income verification", "Bank statements"],
              tips: ["Ensure all documents are clear and valid", "Complete all required fields"]
            }
          }
        },
        {
          id: "manual_review_required",
          if: {
            any: [
              { field: "credit_score", op: "lt", value: 650 },
              { field: "fraud_risk_score", op: "gt", value: 40 },
              { field: "flagged_address", op: "eq", value: true }
            ]
          },
          then: {
            decision: "manual_review",
            weight: 0.5,
            reason: "Manual review required due to risk factors",
            ui_metadata: {
              status_color: "orange",
              icon: "warning",
              next_step: "enhanced_verification",
              estimated_time: "3-5 business days",
              required_docs: ["ID verification", "Address proof", "Income verification", "Bank statements", "Employment letter"],
              additional_steps: ["Phone verification", "Video KYC"],
              tips: ["Prepare all documents in advance", "Ensure reachability for verification calls"]
            }
          }
        },
        {
          id: "application_declined",
          if: {
            any: [
              { field: "credit_score", op: "lt", value: 550 },
              { field: "fraud_risk_score", op: "gt", value: 70 },
              { field: "sanctions_match", op: "eq", value: true }
            ]
          },
          then: {
            decision: "declined",
            weight: 1.0,
            reason: "Application does not meet minimum criteria",
            ui_metadata: {
              status_color: "red",
              icon: "cancel",
              next_step: "declined_info",
              estimated_time: nil,
              decline_reasons: ["Credit score below threshold", "High fraud risk detected"],
              alternative_options: ["Secured credit card", "Credit builder program"],
              reapplication_period: "90 days"
            }
          }
        }
      ]
    }
  end

  # Evaluate with enriched UI metadata
  def self.evaluate(applicant_data)
    setup_rules

    service = DecisionService.instance
    result = service.evaluate(
      rule_id: RULE_ID,
      context: applicant_data
    )

    format_ui_result(result, applicant_data)
  end

  # Real-time evaluation with progress tracking for UI
  def self.evaluate_with_progress(applicant_data)
    steps = []

    # Step 1: Initial validation
    steps << {
      step: 1,
      name: "Validating Application",
      status: "completed",
      timestamp: Time.current,
      duration_ms: 50
    }

    # Step 2: Credit check
    sleep(0.1) # Simulate external API call
    steps << {
      step: 2,
      name: "Running Credit Check",
      status: "completed",
      timestamp: Time.current,
      duration_ms: 120,
      data: { credit_score: applicant_data[:credit_score] }
    }

    # Step 3: Fraud screening
    sleep(0.08)
    steps << {
      step: 3,
      name: "Fraud Screening",
      status: "completed",
      timestamp: Time.current,
      duration_ms: 80,
      data: { fraud_risk_score: applicant_data[:fraud_risk_score] || 10 }
    }

    # Step 4: Decision evaluation
    result = evaluate(applicant_data)
    steps << {
      step: 4,
      name: "Making Decision",
      status: "completed",
      timestamp: Time.current,
      duration_ms: 30,
      data: { decision: result[:decision] }
    }

    result.merge(progress_steps: steps)
  end

  # Batch evaluation with UI progress tracking
  def self.evaluate_batch_with_ui(applicants, &progress_callback)
    total = applicants.size
    results = []

    applicants.each_with_index do |applicant, index|
      result = evaluate(applicant)
      results << result

      # Yield progress to UI
      if block_given?
        progress_callback.call({
          completed: index + 1,
          total: total,
          percentage: ((index + 1) / total.to_f * 100).round(2),
          current_result: result
        })
      end
    end

    {
      total_processed: total,
      results: results,
      summary: generate_batch_summary(results)
    }
  end

  # Generate UI-friendly dashboard metrics
  def self.generate_dashboard_metrics(time_period = 24.hours)
    # This would query actual data in production
    {
      period: "Last 24 Hours",
      total_applications: 1247,
      decisions: {
        instant_approval: { count: 423, percentage: 33.9, trend: "+5.2%" },
        fast_track: { count: 387, percentage: 31.0, trend: "+2.1%" },
        standard_review: { count: 298, percentage: 23.9, trend: "-1.5%" },
        manual_review: { count: 89, percentage: 7.1, trend: "-0.8%" },
        declined: { count: 50, percentage: 4.0, trend: "-2.1%" }
      },
      average_decision_time_ms: 245,
      peak_hour: "14:00-15:00",
      performance: {
        p50_latency_ms: 180,
        p95_latency_ms: 420,
        p99_latency_ms: 650,
        error_rate: 0.02
      },
      top_decline_reasons: [
        { reason: "Low credit score", count: 28 },
        { reason: "High fraud risk", count: 15 },
        { reason: "Sanctions match", count: 7 }
      ]
    }
  end

  def self.setup_rules
    service = DecisionService.instance

    rule = Rule.find_or_initialize_by(rule_id: RULE_ID)
    rule.ruleset = 'customer_onboarding'
    rule.description = 'Interactive customer onboarding with real-time UI feedback'
    rule.status = 'active'
    rule.save!

    unless rule.active_version
      version = service.save_rule_version(
        rule_id: RULE_ID,
        content: rules_definition,
        created_by: 'system',
        changelog: 'Initial version with UI metadata'
      )
      version.activate!
    end
  end

  private

  def self.format_ui_result(result, applicant_data)
    # Extract UI metadata from matched rule
    ui_metadata = result.dig(:evaluations, 0, :outcome, :ui_metadata) || {}

    {
      application_id: SecureRandom.uuid,
      applicant: applicant_data.slice(:name, :email),
      decision: result[:decision] || 'pending',
      confidence: result[:confidence] || 0,
      timestamp: Time.current,

      # UI-specific fields
      ui: {
        status_color: ui_metadata[:status_color] || 'gray',
        status_icon: ui_metadata[:icon] || 'info',
        next_step: ui_metadata[:next_step],
        estimated_time: ui_metadata[:estimated_time],
        required_documents: ui_metadata[:required_docs] || [],
        additional_steps: ui_metadata[:additional_steps] || [],
        benefits: ui_metadata[:benefits] || [],
        tips: ui_metadata[:tips] || [],
        alternative_options: ui_metadata[:alternative_options] || []
      },

      # Decision details
      decision_details: {
        primary_reason: result[:explanations]&.first || 'Processing',
        all_explanations: result[:explanations] || [],
        confidence_percentage: (result[:confidence] * 100).round(2),
        rules_evaluated: result[:evaluations]&.size || 0
      },

      # Metadata for tracking
      metadata: {
        evaluation_time_ms: ((result[:audit_payload]&.dig(:evaluation_time) || 0.1) * 1000).round(2),
        rule_version: result[:audit_payload]&.dig(:rule_version),
        evaluated_at: Time.current.iso8601
      }
    }
  end

  def self.generate_batch_summary(results)
    decision_counts = results.group_by { |r| r[:decision] }
                            .transform_values(&:count)

    {
      total: results.size,
      by_decision: decision_counts,
      average_confidence: (results.sum { |r| r[:confidence] } / results.size.to_f).round(3),
      total_processing_time_ms: results.sum { |r| r.dig(:metadata, :evaluation_time_ms) || 0 }.round(2)
    }
  end
end
