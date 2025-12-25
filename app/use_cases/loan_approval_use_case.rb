# Loan Approval Use Case
# Demonstrates complex decision logic with multiple factors
class LoanApprovalUseCase
  RULE_ID = 'loan_approval_v1'

  def self.rule_definition
    {
      rule_id: RULE_ID,
      name: 'Loan Approval Decision',
      description: 'Determines loan approval based on credit score, income, and debt ratio',
      version: '1.0',
      conditions: [
        {
          all: [
            { fact: 'credit_score', operator: 'greaterThanInclusive', value: 650 },
            { fact: 'annual_income', operator: 'greaterThanInclusive', value: 30000 },
            { fact: 'debt_to_income_ratio', operator: 'lessThanInclusive', value: 0.43 },
            { fact: 'employment_years', operator: 'greaterThanInclusive', value: 2 }
          ]
        }
      ],
      event: {
        type: 'loan_approved',
        params: {
          status: 'approved',
          max_amount: 250000,
          interest_rate: 3.5,
          message: 'Congratulations! Your loan application has been approved.'
        }
      },
      priority: 100
    }
  end

  def self.premium_tier_rule
    {
      rule_id: 'loan_approval_premium',
      name: 'Premium Loan Approval',
      description: 'Premium tier for excellent credit',
      version: '1.0',
      conditions: [
        {
          all: [
            { fact: 'credit_score', operator: 'greaterThanInclusive', value: 750 },
            { fact: 'annual_income', operator: 'greaterThanInclusive', value: 75000 },
            { fact: 'debt_to_income_ratio', operator: 'lessThanInclusive', value: 0.30 }
          ]
        }
      ],
      event: {
        type: 'loan_approved_premium',
        params: {
          status: 'approved',
          max_amount: 500000,
          interest_rate: 2.9,
          tier: 'premium',
          message: 'Congratulations! You qualify for our premium loan program.'
        }
      },
      priority: 200
    }
  end

  def self.conditional_approval_rule
    {
      rule_id: 'loan_approval_conditional',
      name: 'Conditional Loan Approval',
      description: 'Requires additional documentation',
      version: '1.0',
      conditions: [
        {
          any: [
            {
              all: [
                { fact: 'credit_score', operator: 'greaterThanInclusive', value: 600 },
                { fact: 'credit_score', operator: 'lessThan', value: 650 },
                { fact: 'annual_income', operator: 'greaterThanInclusive', value: 40000 }
              ]
            },
            {
              all: [
                { fact: 'credit_score', operator: 'greaterThanInclusive', value: 650 },
                { fact: 'employment_years', operator: 'lessThan', value: 2 },
                { fact: 'debt_to_income_ratio', operator: 'lessThanInclusive', value: 0.35 }
              ]
            }
          ]
        }
      ],
      event: {
        type: 'loan_conditional',
        params: {
          status: 'conditional',
          max_amount: 150000,
          interest_rate: 4.5,
          required_documents: ['pay_stubs', 'tax_returns', 'bank_statements'],
          message: 'Your application requires additional documentation for approval.'
        }
      },
      priority: 50
    }
  end

  def self.rejection_rule
    {
      rule_id: 'loan_rejection',
      name: 'Loan Rejection',
      description: 'Default rejection for applications that don\'t meet criteria',
      version: '1.0',
      conditions: [
        {
          any: [
            { fact: 'credit_score', operator: 'lessThan', value: 600 },
            { fact: 'annual_income', operator: 'lessThan', value: 25000 },
            { fact: 'debt_to_income_ratio', operator: 'greaterThan', value: 0.50 }
          ]
        }
      ],
      event: {
        type: 'loan_rejected',
        params: {
          status: 'rejected',
          reasons: [],
          message: 'Unfortunately, your application does not meet our current lending criteria.'
        }
      },
      priority: 10
    }
  end

  # Evaluate a loan application
  def self.evaluate(applicant_data)
    service = DecisionService.instance

    # Combine all rules into a ruleset
    ruleset = {
      rules: [
        premium_tier_rule,
        rule_definition,
        conditional_approval_rule,
        rejection_rule
      ]
    }

    # Ensure the rule exists
    setup_rules

    result = service.evaluate(
      rule_id: RULE_ID,
      context: applicant_data
    )

    format_result(result, applicant_data)
  end

  # Setup rules in database
  def self.setup_rules
    service = DecisionService.instance

    [
      { rule_id: RULE_ID, definition: rule_definition },
      { rule_id: 'loan_approval_premium', definition: premium_tier_rule },
      { rule_id: 'loan_approval_conditional', definition: conditional_approval_rule },
      { rule_id: 'loan_rejection', definition: rejection_rule }
    ].each do |rule_data|
      rule = Rule.find_or_initialize_by(rule_id: rule_data[:rule_id])
      rule.ruleset = 'loan_approval'
      rule.description = rule_data[:definition][:description]
      rule.status = 'active'
      rule.save!

      # Create initial version if none exists
      unless rule.active_version
        service.save_rule_version(
          rule_id: rule.rule_id,
          content: rule_data[:definition],
          created_by: 'system',
          changelog: 'Initial version'
        )
        rule.rule_versions.first&.activate!
      end
    end
  end

  private

  def self.format_result(result, applicant_data)
    {
      applicant: applicant_data.slice(:name, :email),
      decision: result.dig(:event, :params, :status) || 'pending',
      details: result[:event]&.dig(:params) || {},
      evaluated_at: Time.current,
      rule_triggered: result[:event]&.dig(:type)
    }
  end
end
