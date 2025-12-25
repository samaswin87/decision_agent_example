# Simple Loan Approval Use Case
# Demonstrates DecisionAgent with JSON rules
class SimpleLoanUseCase
  RULE_ID = 'simple_loan_approval'

  def self.rules_definition
    {
      version: "1.0",
      ruleset: "loan_approval",
      description: "Simple loan approval rules",
      rules: [
        {
          id: "premium_approval",
          if: {
            all: [
              { field: "credit_score", op: "gte", value: 750 },
              { field: "annual_income", op: "gte", value: 75000 }
            ]
          },
          then: {
            decision: "approved",
            weight: 1.0,
            reason: "Premium tier - excellent credit and income"
          }
        },
        {
          id: "standard_approval",
          if: {
            all: [
              { field: "credit_score", op: "gte", value: 650 },
              { field: "annual_income", op: "gte", value: 30000 },
              { field: "debt_to_income_ratio", op: "lte", value: 0.43 }
            ]
          },
          then: {
            decision: "approved",
            weight: 0.8,
            reason: "Standard approval - meets minimum requirements"
          }
        },
        {
          id: "conditional_approval",
          if: {
            all: [
              { field: "credit_score", op: "gte", value: 600 },
              { field: "annual_income", op: "gte", value: 25000 }
            ]
          },
          then: {
            decision: "conditional",
            weight: 0.6,
            reason: "Conditional approval - additional documentation required"
          }
        },
        {
          id: "rejection",
          if: {
            any: [
              { field: "credit_score", op: "lt", value: 600 },
              { field: "annual_income", op: "lt", value: 25000 }
            ]
          },
          then: {
            decision: "rejected",
            weight: 1.0,
            reason: "Does not meet minimum criteria"
          }
        }
      ]
    }
  end

  def self.evaluate(applicant_data)
    service = DecisionService.instance
    result = service.evaluate(
      rule_id: RULE_ID,
      context: applicant_data
    )

    format_result(result, applicant_data)
  end

  def self.setup_rules
    service = DecisionService.instance

    rule = Rule.find_or_initialize_by(rule_id: RULE_ID)
    rule.ruleset = 'loan_approval'
    rule.description = 'Simple loan approval rules'
    rule.status = 'active'
    rule.save!

    unless rule.active_version
      version = service.save_rule_version(
        rule_id: RULE_ID,
        content: rules_definition,
        created_by: 'system',
        changelog: 'Initial version'
      )
      version.activate!
    end
  end

  def self.evaluate_batch(applicants, parallel: false)
    setup_rules

    start_time = Time.current

    results = if parallel
      applicants.map do |applicant|
        Thread.new { evaluate(applicant) }
      end.map(&:value)
    else
      applicants.map { |applicant| evaluate(applicant) }
    end

    end_time = Time.current
    duration = end_time - start_time

    {
      results: results,
      performance: {
        total_evaluations: applicants.size,
        duration_seconds: duration.round(3),
        average_per_evaluation_ms: ((duration / applicants.size) * 1000).round(2),
        evaluations_per_second: (applicants.size / duration).round(2),
        parallel: parallel,
        started_at: start_time,
        completed_at: end_time
      }
    }
  end

  private

  def self.format_result(result, applicant_data)
    {
      applicant: applicant_data.slice(:name, :email),
      decision: result[:decision] || 'pending',
      confidence: result[:confidence] || 0,
      explanations: result[:explanations] || [],
      evaluated_at: Time.current
    }
  end
end
