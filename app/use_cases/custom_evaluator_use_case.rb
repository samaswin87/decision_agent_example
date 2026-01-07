# Custom Evaluator Use Case
# Demonstrates creating and using custom evaluators with DecisionAgent
# Shows how to extend DecisionAgent::Evaluators::Base for custom logic
class CustomEvaluatorUseCase
  # Custom evaluator for risk assessment
  class RiskAssessmentEvaluator < DecisionAgent::Evaluators::Base
    def evaluate(context, feedback: {})
      risk_score = calculate_risk_score(context)

      case risk_score
      when 0.0..0.3
        DecisionAgent::Evaluation.new(
          decision: "low_risk",
          weight: 0.9,
          reason: "Low risk profile detected",
          evaluator_name: "risk_assessment",
          metadata: { risk_score: risk_score }
        )
      when 0.3..0.7
        DecisionAgent::Evaluation.new(
          decision: "medium_risk",
          weight: 0.6,
          reason: "Moderate risk profile",
          evaluator_name: "risk_assessment",
          metadata: { risk_score: risk_score }
        )
      else
        DecisionAgent::Evaluation.new(
          decision: "high_risk",
          weight: 0.9,
          reason: "High risk profile detected",
          evaluator_name: "risk_assessment",
          metadata: { risk_score: risk_score }
        )
      end
    end

    private

    def calculate_risk_score(context)
      factors = []
      
      # Age factor
      if context[:age]
        factors << (context[:age] < 18 || context[:age] > 75 ? 0.3 : 0.0)
      end

      # Credit score factor
      if context[:credit_score]
        if context[:credit_score] < 600
          factors << 0.4
        elsif context[:credit_score] < 700
          factors << 0.2
        else
          factors << 0.0
        end
      end

      # Employment factor
      if context[:employment_status] == 'unemployed'
        factors << 0.3
      elsif context[:employment_years] && context[:employment_years] < 1
        factors << 0.2
      else
        factors << 0.0
      end

      # Debt factor
      if context[:debt_to_income_ratio]
        if context[:debt_to_income_ratio] > 0.5
          factors << 0.4
        elsif context[:debt_to_income_ratio] > 0.3
          factors << 0.2
        else
          factors << 0.0
        end
      end

      # Calculate average risk
      factors.any? ? factors.sum / factors.length : 0.5
    end
  end

  # Custom evaluator for fraud detection
  class FraudDetectionEvaluator < DecisionAgent::Evaluators::Base
    def evaluate(context, feedback: {})
      fraud_indicators = count_fraud_indicators(context)

      case fraud_indicators
      when 0
        DecisionAgent::Evaluation.new(
          decision: "safe",
          weight: 0.95,
          reason: "No fraud indicators detected",
          evaluator_name: "fraud_detection",
          metadata: { indicators: fraud_indicators }
        )
      when 1..2
        DecisionAgent::Evaluation.new(
          decision: "review",
          weight: 0.7,
          reason: "Some fraud indicators present",
          evaluator_name: "fraud_detection",
          metadata: { indicators: fraud_indicators }
        )
      else
        DecisionAgent::Evaluation.new(
          decision: "fraud",
          weight: 0.95,
          reason: "Multiple fraud indicators detected",
          evaluator_name: "fraud_detection",
          metadata: { indicators: fraud_indicators }
        )
      end
    end

    private

    def count_fraud_indicators(context)
      count = 0
      
      count += 1 if context[:device_mismatch] == true
      count += 1 if context[:location_mismatch] == true
      count += 1 if context[:unusual_transaction_pattern] == true
      count += 1 if context[:velocity_check_failed] == true
      count += 1 if context[:ip_reputation_score] && context[:ip_reputation_score] < 30
      count += 1 if context[:transaction_amount] && context[:transaction_amount] > 10000

      count
    end
  end

  # Custom evaluator for eligibility scoring
  class EligibilityScoringEvaluator < DecisionAgent::Evaluators::Base
    def evaluate(context, feedback: {})
      eligibility_score = calculate_eligibility(context)

      case eligibility_score
      when 0.8..1.0
        DecisionAgent::Evaluation.new(
          decision: "highly_eligible",
          weight: eligibility_score,
          reason: "Highly eligible candidate",
          evaluator_name: "eligibility_scoring",
          metadata: { eligibility_score: eligibility_score }
        )
      when 0.5..0.8
        DecisionAgent::Evaluation.new(
          decision: "eligible",
          weight: eligibility_score,
          reason: "Eligible candidate",
          evaluator_name: "eligibility_scoring",
          metadata: { eligibility_score: eligibility_score }
        )
      else
        DecisionAgent::Evaluation.new(
          decision: "not_eligible",
          weight: 1.0 - eligibility_score,
          reason: "Not eligible",
          evaluator_name: "eligibility_scoring",
          metadata: { eligibility_score: eligibility_score }
        )
      end
    end

    private

    def calculate_eligibility(context)
      score = 0.0
      factors = 0

      # Age eligibility
      if context[:age] && context[:age] >= 18 && context[:age] <= 65
        score += 0.3
        factors += 1
      end

      # Income eligibility
      if context[:income] && context[:income] >= 30000
        score += 0.3
        factors += 1
      end

      # Credit eligibility
      if context[:credit_score] && context[:credit_score] >= 650
        score += 0.2
        factors += 1
      end

      # Employment eligibility
      if context[:employment_status] == 'employed' && context[:employment_years] && context[:employment_years] >= 2
        score += 0.2
        factors += 1
      end

      factors > 0 ? score : 0.0
    end
  end

  class << self
    # Evaluate with custom risk assessment evaluator
    def evaluate_risk(context)
      evaluator = RiskAssessmentEvaluator.new
      agent = DecisionAgent::Agent.new(
        evaluators: [evaluator],
        scoring_strategy: DecisionAgent::Scoring::WeightedAverage.new
      )

      decision = agent.decide(context: context)
      
      {
        decision: decision.decision,
        confidence: decision.confidence,
        explanations: decision.explanations,
        risk_score: decision.evaluations.first&.metadata&.dig(:risk_score)
      }
    end

    # Evaluate with custom fraud detection evaluator
    def evaluate_fraud(context)
      evaluator = FraudDetectionEvaluator.new
      agent = DecisionAgent::Agent.new(
        evaluators: [evaluator],
        scoring_strategy: DecisionAgent::Scoring::WeightedAverage.new
      )

      decision = agent.decide(context: context)
      
      {
        decision: decision.decision,
        confidence: decision.confidence,
        explanations: decision.explanations,
        fraud_indicators: decision.evaluations.first&.metadata&.dig(:indicators)
      }
    end

    # Evaluate with custom eligibility scoring evaluator
    def evaluate_eligibility(context)
      evaluator = EligibilityScoringEvaluator.new
      agent = DecisionAgent::Agent.new(
        evaluators: [evaluator],
        scoring_strategy: DecisionAgent::Scoring::WeightedAverage.new
      )

      decision = agent.decide(context: context)
      
      {
        decision: decision.decision,
        confidence: decision.confidence,
        explanations: decision.explanations,
        eligibility_score: decision.evaluations.first&.metadata&.dig(:eligibility_score)
      }
    end

    # Evaluate with multiple custom evaluators
    def evaluate_multi_evaluator(context)
      risk_evaluator = RiskAssessmentEvaluator.new
      fraud_evaluator = FraudDetectionEvaluator.new
      eligibility_evaluator = EligibilityScoringEvaluator.new

      agent = DecisionAgent::Agent.new(
        evaluators: [risk_evaluator, fraud_evaluator, eligibility_evaluator],
        scoring_strategy: DecisionAgent::Scoring::WeightedAverage.new
      )

      decision = agent.decide(context: context)
      
      {
        decision: decision.decision,
        confidence: decision.confidence,
        explanations: decision.explanations,
        evaluations: decision.evaluations.map do |eval|
          {
            evaluator: eval.evaluator_name,
            decision: eval.decision,
            weight: eval.weight,
            metadata: eval.metadata
          }
        end
      }
    end

    # Run example evaluations
    def run_examples
      puts "\n=== Custom Evaluator Use Case Examples ===\n"
      
      # Example 1: Risk Assessment
      puts "1. Risk Assessment:"
      context1 = {
        age: 35,
        credit_score: 720,
        employment_status: 'employed',
        employment_years: 5,
        debt_to_income_ratio: 0.25
      }
      result1 = evaluate_risk(context1)
      puts "   Context: #{context1.inspect}"
      puts "   Result: #{result1[:decision]} (risk_score: #{result1[:risk_score]})"
      
      # Example 2: Fraud Detection
      puts "\n2. Fraud Detection:"
      context2 = {
        device_mismatch: true,
        location_mismatch: false,
        unusual_transaction_pattern: true,
        velocity_check_failed: false,
        ip_reputation_score: 45,
        transaction_amount: 5000
      }
      result2 = evaluate_fraud(context2)
      puts "   Context: #{context2.inspect}"
      puts "   Result: #{result2[:decision]} (indicators: #{result2[:fraud_indicators]})"
      
      # Example 3: Eligibility Scoring
      puts "\n3. Eligibility Scoring:"
      context3 = {
        age: 30,
        income: 50000,
        credit_score: 680,
        employment_status: 'employed',
        employment_years: 3
      }
      result3 = evaluate_eligibility(context3)
      puts "   Context: #{context3.inspect}"
      puts "   Result: #{result3[:decision]} (score: #{result3[:eligibility_score]})"
      
      # Example 4: Multi-Evaluator
      puts "\n4. Multi-Evaluator:"
      context4 = {
        age: 28,
        credit_score: 750,
        employment_status: 'employed',
        employment_years: 4,
        debt_to_income_ratio: 0.20,
        device_mismatch: false,
        location_mismatch: false,
        income: 60000
      }
      result4 = evaluate_multi_evaluator(context4)
      puts "   Context: #{context4.inspect}"
      puts "   Result: #{result4[:decision]} (confidence: #{result4[:confidence]})"
      puts "   Evaluations:"
      result4[:evaluations].each do |eval|
        puts "     - #{eval[:evaluator]}: #{eval[:decision]} (weight: #{eval[:weight]})"
      end
      
      puts "\n=== Examples Complete ===\n"
    end
  end
end

