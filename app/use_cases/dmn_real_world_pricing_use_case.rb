# frozen_string_literal: true

# DMN Real-World Pricing Use Case
# Demonstrates complex e-commerce pricing with customer segments, categories, and promotions
class DmnRealWorldPricingUseCase
  RULE_ID = 'dmn_real_world_pricing'

  def self.dmn_xml
    <<~DMN
      <?xml version="1.0" encoding="UTF-8"?>
      <definitions xmlns="https://www.omg.org/spec/DMN/20191111/MODEL/"
                   id="dynamic_pricing"
                   name="Dynamic Pricing Decision"
                   namespace="http://example.com/pricing">

        <decision id="pricing" name="Calculate Final Price">
          <decisionTable id="pricing_table" hitPolicy="PRIORITY">
            <input id="input_segment" label="Customer Segment">
              <inputExpression typeRef="string">
                <text>customer_segment</text>
              </inputExpression>
            </input>

            <input id="input_category" label="Product Category">
              <inputExpression typeRef="string">
                <text>product_category</text>
              </inputExpression>
            </input>

            <input id="input_quantity" label="Quantity">
              <inputExpression typeRef="number">
                <text>quantity</text>
              </inputExpression>
            </input>

            <input id="input_promo" label="Promotional Code">
              <inputExpression typeRef="string">
                <text>promo_code</text>
              </inputExpression>
            </input>

            <output id="output_discount" label="Discount Percentage" name="discount" typeRef="number"/>
            <output id="output_tier" label="Pricing Tier" name="tier" typeRef="string"/>

            <rule id="rule_vip_electronics">
              <description>VIP customers buying electronics</description>
              <inputEntry><text>"vip"</text></inputEntry>
              <inputEntry><text>"electronics"</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <outputEntry><text>0.25</text></outputEntry>
              <outputEntry><text>"vip"</text></outputEntry>
            </rule>

            <rule id="rule_bulk_electronics">
              <description>Bulk purchase of electronics (10+ units)</description>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>"electronics"</text></inputEntry>
              <inputEntry><text>>= 10</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <outputEntry><text>0.20</text></outputEntry>
              <outputEntry><text>"bulk"</text></outputEntry>
            </rule>

            <rule id="rule_promo_summer">
              <description>Summer sale promotional code</description>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>"SUMMER2024"</text></inputEntry>
              <outputEntry><text>0.15</text></outputEntry>
              <outputEntry><text>"promotional"</text></outputEntry>
            </rule>

            <rule id="rule_books_standard">
              <description>Standard discount for books</description>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>"books"</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <outputEntry><text>0.10</text></outputEntry>
              <outputEntry><text>"standard"</text></outputEntry>
            </rule>

            <rule id="rule_premium">
              <description>Premium customers get standard discount</description>
              <inputEntry><text>"premium"</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <outputEntry><text>0.10</text></outputEntry>
              <outputEntry><text>"premium"</text></outputEntry>
            </rule>

            <rule id="rule_default">
              <description>Default pricing - no discount</description>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <outputEntry><text>0.00</text></outputEntry>
              <outputEntry><text>"standard"</text></outputEntry>
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
    Rails.logger.error("DMN pricing setup failed: #{e.message}")
    raise
  end

  def self.evaluate(context)
    require 'decision_agent'
    require 'decision_agent/dmn/importer'
    require 'decision_agent/evaluators/dmn_evaluator'

    # Setup if needed
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
      decision_id: 'pricing'
    )

    ctx = DecisionAgent::Context.new(context)
    evaluation = evaluator.evaluate(ctx)

    # Handle case where evaluation might be a String (error message)
    if evaluation.is_a?(String)
      return { error: evaluation, context: context }
    end

    discount_pct = (evaluation.decision * 100).round(0)
    tier = evaluation.metadata && evaluation.metadata[:outputs] ? evaluation.metadata[:outputs][:tier] : nil

    {
      decision: evaluation.decision,
      discount_percentage: discount_pct,
      tier: tier,
      confidence: evaluation.weight,
      reason: evaluation.respond_to?(:reason) ? evaluation.reason : nil,
      metadata: evaluation.respond_to?(:metadata) ? evaluation.metadata : nil,
      context: context
    }
  rescue StandardError => e
    Rails.logger.error("DMN pricing evaluation failed: #{e.message}")
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

