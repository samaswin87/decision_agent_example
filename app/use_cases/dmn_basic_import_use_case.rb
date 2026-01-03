# frozen_string_literal: true

# DMN Basic Import Use Case
# Demonstrates importing and using DMN decision models
class DmnBasicImportUseCase
  RULE_ID = 'dmn_basic_import'

  def self.dmn_xml
    <<~DMN
      <?xml version="1.0" encoding="UTF-8"?>
      <definitions xmlns="https://www.omg.org/spec/DMN/20191111/MODEL/"
                   id="loan_approval"
                   name="Loan Approval Decision"
                   namespace="http://example.com/dmn">

        <decision id="loan_decision" name="Loan Approval">
          <decisionTable id="loan_table" hitPolicy="FIRST">
            <input id="input_credit" label="Credit Score">
              <inputExpression typeRef="number">
                <text>credit_score</text>
              </inputExpression>
            </input>

            <input id="input_income" label="Annual Income">
              <inputExpression typeRef="number">
                <text>income</text>
              </inputExpression>
            </input>

            <output id="output_decision" label="Decision" name="decision" typeRef="string"/>

            <rule id="rule_1">
              <description>Approve excellent credit with high income</description>
              <inputEntry id="entry_1_credit">
                <text>>= 750</text>
              </inputEntry>
              <inputEntry id="entry_1_income">
                <text>>= 75000</text>
              </inputEntry>
              <outputEntry id="output_1">
                <text>"approved"</text>
              </outputEntry>
            </rule>

            <rule id="rule_2">
              <description>Conditional approval for good credit</description>
              <inputEntry id="entry_2_credit">
                <text>>= 650</text>
              </inputEntry>
              <inputEntry id="entry_2_income">
                <text>>= 50000</text>
              </inputEntry>
              <outputEntry id="output_2">
                <text>"conditional"</text>
              </outputEntry>
            </rule>

            <rule id="rule_3">
              <description>Reject low credit or income</description>
              <inputEntry id="entry_3_credit">
                <text>-</text>
              </inputEntry>
              <inputEntry id="entry_3_income">
                <text>-</text>
              </inputEntry>
              <outputEntry id="output_3">
                <text>"rejected"</text>
              </outputEntry>
            </rule>
          </decisionTable>
        </decision>
      </definitions>
    DMN
  end

  def self.setup_rules
    require 'decision_agent'
    require 'decision_agent/dmn/importer'

    importer = DecisionAgent::Dmn::Importer.new
    result = importer.import_from_xml(
      dmn_xml,
      ruleset_name: RULE_ID,
      created_by: 'demo_user'
    )

    result
  rescue StandardError => e
    Rails.logger.error("DMN import failed: #{e.message}")
    raise
  end

  def self.evaluate(context)
    require 'decision_agent'
    require 'decision_agent/dmn/importer'
    require 'decision_agent/evaluators/dmn_evaluator'

    # Import the DMN XML (setup stores it in versioning system)
    setup_rules unless model_exists?

    # Import directly from XML for evaluation
    importer = DecisionAgent::Dmn::Importer.new
    result = importer.import_from_xml(
      dmn_xml,
      ruleset_name: "#{RULE_ID}_eval",
      created_by: 'demo_user'
    )

    evaluator = DecisionAgent::Evaluators::DmnEvaluator.new(
      model: result[:model],
      decision_id: 'loan_decision'
    )

    ctx = DecisionAgent::Context.new(context)
    evaluation = evaluator.evaluate(ctx)

    # Handle case where evaluation might be a String (error message)
    if evaluation.is_a?(String)
      return { error: evaluation, context: context }
    end

    {
      decision: evaluation.decision,
      confidence: evaluation.weight,
      reason: evaluation.respond_to?(:reason) ? evaluation.reason : nil,
      metadata: evaluation.respond_to?(:metadata) ? evaluation.metadata : nil,
      context: context
    }
  rescue StandardError => e
    Rails.logger.error("DMN evaluation failed: #{e.message}")
    { error: e.message, context: context }
  end

  def self.model_exists?
    version_manager = DecisionAgent::Versioning::VersionManager.new(
      adapter: DecisionAgent::Versioning::ActiveRecordAdapter.new
    )
    version_manager.get_active_version(rule_id: RULE_ID).present?
  rescue
    false
  end
end

