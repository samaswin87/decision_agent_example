require 'test_helper'

class LoanApprovalUseCaseTest < ActiveSupport::TestCase
  setup do
    LoanApprovalUseCase.setup_rules
  end

  test "approves loan for qualified applicant" do
    applicant = {
      name: 'John Doe',
      email: 'john@example.com',
      credit_score: 720,
      annual_income: 75000,
      debt_to_income_ratio: 0.35,
      employment_years: 5
    }

    result = LoanApprovalUseCase.evaluate(applicant)

    assert_equal 'approved', result[:decision]
    assert result[:details][:max_amount].present?
    assert result[:details][:interest_rate].present?
  end

  test "approves premium tier for excellent credit" do
    applicant = {
      name: 'Jane Smith',
      email: 'jane@example.com',
      credit_score: 800,
      annual_income: 120000,
      debt_to_income_ratio: 0.25,
      employment_years: 10
    }

    result = LoanApprovalUseCase.evaluate(applicant)

    assert_equal 'approved', result[:decision]
    assert_equal 'premium', result[:details][:tier]
    assert_equal 500000, result[:details][:max_amount]
    assert result[:details][:interest_rate] < 3.5
  end

  test "conditional approval for borderline applicant" do
    applicant = {
      name: 'Bob Johnson',
      email: 'bob@example.com',
      credit_score: 630,
      annual_income: 45000,
      debt_to_income_ratio: 0.38,
      employment_years: 3
    }

    result = LoanApprovalUseCase.evaluate(applicant)

    assert_equal 'conditional', result[:decision]
    assert result[:details][:required_documents].present?
    assert result[:details][:required_documents].include?('pay_stubs')
  end

  test "rejects loan for low credit score" do
    applicant = {
      name: 'Poor Credit',
      email: 'poor@example.com',
      credit_score: 550,
      annual_income: 60000,
      debt_to_income_ratio: 0.40,
      employment_years: 5
    }

    result = LoanApprovalUseCase.evaluate(applicant)

    assert_equal 'rejected', result[:decision]
    assert_match /does not meet/, result[:details][:message]
  end

  test "rejects loan for insufficient income" do
    applicant = {
      name: 'Low Income',
      email: 'low@example.com',
      credit_score: 700,
      annual_income: 20000,
      debt_to_income_ratio: 0.30,
      employment_years: 3
    }

    result = LoanApprovalUseCase.evaluate(applicant)

    assert_equal 'rejected', result[:decision]
  end

  test "rejects loan for high debt ratio" do
    applicant = {
      name: 'High Debt',
      email: 'debt@example.com',
      credit_score: 680,
      annual_income: 50000,
      debt_to_income_ratio: 0.55,
      employment_years: 4
    }

    result = LoanApprovalUseCase.evaluate(applicant)

    assert_equal 'rejected', result[:decision]
  end

  test "includes applicant info in result" do
    applicant = {
      name: 'Test User',
      email: 'test@example.com',
      credit_score: 700,
      annual_income: 50000,
      debt_to_income_ratio: 0.40,
      employment_years: 3
    }

    result = LoanApprovalUseCase.evaluate(applicant)

    assert_equal 'Test User', result[:applicant][:name]
    assert_equal 'test@example.com', result[:applicant][:email]
    assert result[:evaluated_at].present?
  end

  test "all rules are created in database" do
    assert Rule.exists?(rule_id: 'loan_approval_v1')
    assert Rule.exists?(rule_id: 'loan_approval_premium')
    assert Rule.exists?(rule_id: 'loan_approval_conditional')
    assert Rule.exists?(rule_id: 'loan_rejection')
  end

  test "all rules have active versions" do
    %w[loan_approval_v1 loan_approval_premium loan_approval_conditional loan_rejection].each do |rule_id|
      rule = Rule.find_by(rule_id: rule_id)
      assert rule.active_version.present?, "#{rule_id} should have an active version"
    end
  end
end
