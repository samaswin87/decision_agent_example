# frozen_string_literal: true

# DMN Combining Evaluators Use Case
# Demonstrates using DMN and JSON evaluators together
class DmnCombiningEvaluatorsUseCase
  RULE_ID = 'dmn_combining_evaluators'

  def self.dmn_xml
    <<~DMN
      <?xml version="1.0" encoding="UTF-8"?>
      <definitions xmlns="https://www.omg.org/spec/DMN/20191111/MODEL/"
                   id="credit_assessment"
                   name="Credit Risk Assessment"
                   namespace="http://example.com/credit">

        <decision id="credit_risk" name="Credit Risk Level">
          <decisionTable id="credit_table" hitPolicy="FIRST">
            <input id="input_score" label="Credit Score">
              <inputExpression typeRef="number">
                <text>credit_score</text>
              </inputExpression>
            </input>

            <output id="output_risk" label="Risk Level" name="risk" typeRef="string"/>

            <rule id="rule_low">
              <inputEntry><text>>= 700</text></inputEntry>
              <outputEntry><text>"low"</text></outputEntry>
            </rule>

            <rule id="rule_medium">
              <inputEntry><text>>= 600</text></inputEntry>
              <outputEntry><text>"medium"</text></outputEntry>
            </rule>

            <rule id="rule_high">
              <inputEntry><text>-</text></inputEntry>
              <outputEntry><text>"high"</text></outputEntry>
            </rule>
          </decisionTable>
        </decision>
      </definitions>
    DMN
  end

  def self.json_rules
    {
      version: "1.0",
      ruleset: "business_policies",
      description: "Business policy overrides and special cases",
      rules: [
        {
          id: "vip_customer",
          if: { field: "customer_tier", op: "eq", value: "platinum" },
          then: {
            decision: "approve_vip",
            weight: 1.0,
            reason: "Platinum tier customers get automatic approval"
          }
        },
        {
          id: "fraud_flag",
          if: { field: "fraud_alert", op: "eq", value: true },
          then: {
            decision: "reject_fraud",
            weight: 1.0,
            reason: "Fraud alert triggered - automatic rejection"
          }
        },
        {
          id: "new_customer_promotion",
          if: {
            all: [
              { field: "customer_age_days", op: "lt", value: 30 },
              { field: "promotional_code", op: "eq", value: "NEWCUST2024" }
            ]
          },
          then: {
            decision: "approve_promotion",
            weight: 0.8,
            reason: "New customer promotion - conditional approval"
          }
        }
      ]
    }
  end

  def self.setup_rules
    require 'decision_agent'
    require 'decision_agent/dmn/importer'

    importer = DecisionAgent::Dmn::Importer.new
    result = importer.import_from_xml(
      dmn_xml,
      ruleset_name: "#{RULE_ID}_dmn",
      created_by: 'demo_user'
    )

    # Also store JSON rules
    service = DecisionService.instance
    service.save_rule_version(
      rule_id: "#{RULE_ID}_json",
      content: json_rules,
      created_by: 'demo_user',
      changelog: 'Business policy rules'
    )

    result
  rescue StandardError => e
    Rails.logger.error("DMN combining evaluators setup failed: #{e.message}")
    raise
  end

  def self.evaluate(context)
    require 'decision_agent'
    require 'decision_agent/dmn/importer'
    require 'decision_agent/evaluators/dmn_evaluator'
    require 'decision_agent/evaluators/json_rule_evaluator'

    # Setup if needed
    setup_rules unless model_exists?

    # Import DMN directly from XML
    importer = DecisionAgent::Dmn::Importer.new
    dmn_result = importer.import_from_xml(
      dmn_xml,
      ruleset_name: "#{RULE_ID}_dmn_eval",
      created_by: 'demo_user'
    )

    dmn_evaluator = DecisionAgent::Evaluators::DmnEvaluator.new(
      model: dmn_result[:model],
      decision_id: 'credit_risk',
      name: 'CreditRiskEvaluator'
    )

    # Create JSON evaluator
    json_evaluator = DecisionAgent::Evaluators::JsonRuleEvaluator.new(
      rules_json: json_rules,
      name: 'BusinessPolicyEvaluator'
    )

    # Create agent with both evaluators
    agent = DecisionAgent::Agent.new(
      evaluators: [dmn_evaluator, json_evaluator]
    )

    ctx = DecisionAgent::Context.new(context)
    decision = agent.decide(context: ctx)

    {
      decision: decision.decision,
      confidence: decision.confidence,
      explanations: decision.explanations.map do |expl|
        expl.respond_to?(:reason) ? expl.reason : (expl.is_a?(String) ? expl : expl.to_s)
      end,
      evaluations: decision.evaluations.map do |eval|
        {
          evaluator_name: eval.respond_to?(:evaluator_name) ? eval.evaluator_name : nil,
          decision: eval.respond_to?(:decision) ? eval.decision : nil,
          weight: eval.respond_to?(:weight) ? eval.weight : nil,
          reason: eval.respond_to?(:reason) ? eval.reason : (eval.is_a?(String) ? eval : nil)
        }
      end,
      context: context
    }
  rescue StandardError => e
    Rails.logger.error("DMN combining evaluators evaluation failed: #{e.message}")
    { error: e.message, context: context }
  end

  def self.model_exists?
    version_manager = DecisionAgent::Versioning::VersionManager.new(
      adapter: DecisionAgent::Versioning::ActiveRecordAdapter.new
    )
    version_manager.get_active_version(rule_id: "#{RULE_ID}_dmn").present?
  rescue
    false
  end
end

