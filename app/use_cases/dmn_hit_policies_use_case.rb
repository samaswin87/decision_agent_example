# frozen_string_literal: true

# DMN Hit Policies Use Case
# Demonstrates different DMN hit policies: UNIQUE, PRIORITY, ANY, COLLECT
class DmnHitPoliciesUseCase
  RULE_IDS = {
    unique: 'dmn_hit_policy_unique',
    priority: 'dmn_hit_policy_priority',
    any: 'dmn_hit_policy_any',
    collect: 'dmn_hit_policy_collect'
  }

  def self.dmn_xml_for_policy(policy)
    case policy
    when :unique
      tax_brackets_dmn
    when :priority
      discount_eligibility_dmn
    when :any
      data_validation_dmn
    when :collect
      product_recommendations_dmn
    end
  end

  def self.tax_brackets_dmn
    <<~DMN
      <?xml version="1.0" encoding="UTF-8"?>
      <definitions xmlns="https://www.omg.org/spec/DMN/20191111/MODEL/"
                   id="tax_brackets"
                   name="Tax Bracket Determination"
                   namespace="http://example.com/tax">

        <decision id="tax_bracket" name="Determine Tax Bracket">
          <decisionTable id="tax_table" hitPolicy="UNIQUE">
            <input id="input_income" label="Annual Income">
              <inputExpression typeRef="number">
                <text>income</text>
              </inputExpression>
            </input>

            <output id="output_bracket" label="Tax Bracket" name="bracket" typeRef="string"/>
            <output id="output_rate" label="Tax Rate" name="rate" typeRef="number"/>

            <rule id="rule_10">
              <description>10% bracket: $0 to $9,999</description>
              <inputEntry><text>[0..10000)</text></inputEntry>
              <outputEntry><text>"10%"</text></outputEntry>
              <outputEntry><text>0.10</text></outputEntry>
            </rule>

            <rule id="rule_15">
              <description>15% bracket: $10,000 to $39,999</description>
              <inputEntry><text>[10000..40000)</text></inputEntry>
              <outputEntry><text>"15%"</text></outputEntry>
              <outputEntry><text>0.15</text></outputEntry>
            </rule>

            <rule id="rule_25">
              <description>25% bracket: $40,000 to $84,999</description>
              <inputEntry><text>[40000..85000)</text></inputEntry>
              <outputEntry><text>"25%"</text></outputEntry>
              <outputEntry><text>0.25</text></outputEntry>
            </rule>

            <rule id="rule_35">
              <description>35% bracket: $85,000 and above</description>
              <inputEntry><text>>= 85000</text></inputEntry>
              <outputEntry><text>"35%"</text></outputEntry>
              <outputEntry><text>0.35</text></outputEntry>
            </rule>
          </decisionTable>
        </decision>
      </definitions>
    DMN
  end

  def self.discount_eligibility_dmn
    <<~DMN
      <?xml version="1.0" encoding="UTF-8"?>
      <definitions xmlns="https://www.omg.org/spec/DMN/20191111/MODEL/"
                   id="discount_eligibility"
                   name="Discount Eligibility Decision"
                   namespace="http://example.com/pricing">

        <decision id="discount" name="Determine Discount">
          <decisionTable id="discount_table" hitPolicy="PRIORITY">
            <input id="input_tier" label="Customer Tier">
              <inputExpression typeRef="string">
                <text>customer_tier</text>
              </inputExpression>
            </input>

            <input id="input_purchase" label="Purchase Amount">
              <inputExpression typeRef="number">
                <text>purchase_amount</text>
              </inputExpression>
            </input>

            <output id="output_discount" label="Discount Percentage" name="discount" typeRef="number"/>

            <rule id="rule_vip">
              <description>VIP customers get 20% discount on any purchase</description>
              <inputEntry><text>"platinum"</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <outputEntry><text>0.20</text></outputEntry>
            </rule>

            <rule id="rule_gold_high">
              <description>Gold customers get 15% on purchases over $500</description>
              <inputEntry><text>"gold"</text></inputEntry>
              <inputEntry><text>> 500</text></inputEntry>
              <outputEntry><text>0.15</text></outputEntry>
            </rule>

            <rule id="rule_gold_standard">
              <description>Gold customers get 10% on standard purchases</description>
              <inputEntry><text>"gold"</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <outputEntry><text>0.10</text></outputEntry>
            </rule>

            <rule id="rule_silver_high">
              <description>Silver customers get 10% on purchases over $300</description>
              <inputEntry><text>"silver"</text></inputEntry>
              <inputEntry><text>> 300</text></inputEntry>
              <outputEntry><text>0.10</text></outputEntry>
            </rule>

            <rule id="rule_silver_standard">
              <description>Silver customers get 5% on standard purchases</description>
              <inputEntry><text>"silver"</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <outputEntry><text>0.05</text></outputEntry>
            </rule>

            <rule id="rule_standard">
              <description>Standard customers get 0% discount</description>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <outputEntry><text>0.00</text></outputEntry>
            </rule>
          </decisionTable>
        </decision>
      </definitions>
    DMN
  end

  def self.data_validation_dmn
    <<~DMN
      <?xml version="1.0" encoding="UTF-8"?>
      <definitions xmlns="https://www.omg.org/spec/DMN/20191111/MODEL/"
                   id="data_validation"
                   name="Data Validation Decision"
                   namespace="http://example.com/validation">

        <decision id="validation" name="Validate User Data">
          <decisionTable id="validation_table" hitPolicy="ANY">
            <input id="input_age" label="Age">
              <inputExpression typeRef="number">
                <text>age</text>
              </inputExpression>
            </input>

            <input id="input_email" label="Email Format Valid">
              <inputExpression typeRef="boolean">
                <text>email_valid</text>
              </inputExpression>
            </input>

            <input id="input_phone" label="Phone Format Valid">
              <inputExpression typeRef="boolean">
                <text>phone_valid</text>
              </inputExpression>
            </input>

            <output id="output_valid" label="Is Valid" name="valid" typeRef="boolean"/>

            <rule id="rule_valid_all">
              <description>All checks pass - valid</description>
              <inputEntry><text>>= 18</text></inputEntry>
              <inputEntry><text>true</text></inputEntry>
              <inputEntry><text>true</text></inputEntry>
              <outputEntry><text>true</text></outputEntry>
            </rule>

            <rule id="rule_valid_age_email">
              <description>Age and email valid - valid</description>
              <inputEntry><text>>= 18</text></inputEntry>
              <inputEntry><text>true</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <outputEntry><text>true</text></outputEntry>
            </rule>

            <rule id="rule_valid_age_phone">
              <description>Age and phone valid - valid</description>
              <inputEntry><text>>= 18</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>true</text></inputEntry>
              <outputEntry><text>true</text></outputEntry>
            </rule>

            <rule id="rule_invalid_age">
              <description>Age too young - invalid</description>
              <inputEntry><text>< 18</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <outputEntry><text>false</text></outputEntry>
            </rule>

            <rule id="rule_invalid_email">
              <description>Email invalid - invalid</description>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>false</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <outputEntry><text>false</text></outputEntry>
            </rule>

            <rule id="rule_invalid_phone">
              <description>Phone invalid - invalid</description>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>false</text></inputEntry>
              <outputEntry><text>false</text></outputEntry>
            </rule>
          </decisionTable>
        </decision>
      </definitions>
    DMN
  end

  def self.product_recommendations_dmn
    <<~DMN
      <?xml version="1.0" encoding="UTF-8"?>
      <definitions xmlns="https://www.omg.org/spec/DMN/20191111/MODEL/"
                   id="product_recommendations"
                   name="Product Recommendation Decision"
                   namespace="http://example.com/recommendations">

        <decision id="recommendations" name="Get Product Recommendations">
          <decisionTable id="recommendation_table" hitPolicy="COLLECT">
            <input id="input_budget" label="Budget">
              <inputExpression typeRef="number">
                <text>budget</text>
              </inputExpression>
            </input>

            <input id="input_category" label="Category Preference">
              <inputExpression typeRef="string">
                <text>category</text>
              </inputExpression>
            </input>

            <output id="output_product" label="Recommended Product" name="product" typeRef="string"/>

            <rule id="rule_laptop_basic">
              <description>Basic laptop for budget under $500</description>
              <inputEntry><text>< 500</text></inputEntry>
              <inputEntry><text>"electronics"</text></inputEntry>
              <outputEntry><text>"Basic Laptop"</text></outputEntry>
            </rule>

            <rule id="rule_laptop_premium">
              <description>Premium laptop for budget over $1000</description>
              <inputEntry><text>>= 1000</text></inputEntry>
              <inputEntry><text>"electronics"</text></inputEntry>
              <outputEntry><text>"Premium Laptop"</text></outputEntry>
            </rule>

            <rule id="rule_tablet">
              <description>Tablet for budget $300-$800</description>
              <inputEntry><text>[300..800]</text></inputEntry>
              <inputEntry><text>"electronics"</text></inputEntry>
              <outputEntry><text>"Tablet"</text></outputEntry>
            </rule>

            <rule id="rule_book_fiction">
              <description>Fiction books for any budget</description>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>"books"</text></inputEntry>
              <outputEntry><text>"Fiction Book"</text></outputEntry>
            </rule>

            <rule id="rule_book_tech">
              <description>Tech books for any budget</description>
              <inputEntry><text>-</text></inputEntry>
              <inputEntry><text>"books"</text></inputEntry>
              <outputEntry><text>"Tech Book"</text></outputEntry>
            </rule>
          </decisionTable>
        </decision>
      </definitions>
    DMN
  end

  def self.setup_rules(policy)
    require 'decision_agent'
    require 'decision_agent/dmn/importer'

    rule_id = RULE_IDS[policy]
    return { error: "Unknown policy: #{policy}" } unless rule_id

    importer = DecisionAgent::Dmn::Importer.new
    result = importer.import_from_xml(
      dmn_xml_for_policy(policy),
      ruleset_name: rule_id,
      created_by: 'demo_user'
    )

    result
  rescue StandardError => e
    Rails.logger.error("DMN import failed for #{policy}: #{e.message}")
    { error: e.message }
  end

  def self.evaluate(policy, context)
    require 'decision_agent'
    require 'decision_agent/dmn/importer'
    require 'decision_agent/evaluators/dmn_evaluator'

    rule_id = RULE_IDS[policy]
    return { error: "Unknown policy: #{policy}" } unless rule_id

    decision_id = case policy
                  when :unique then 'tax_bracket'
                  when :priority then 'discount'
                  when :any then 'validation'
                  when :collect then 'recommendations'
                  end

    # Validate input for UNIQUE policy
    if policy == :unique
      income = context[:income] || context['income']
      if income.nil?
        return { error: "Income is required for UNIQUE hit policy evaluation", context: context, policy: policy.to_s }
      end
      income = income.to_f
      if income < 0
        return { error: "Income must be a non-negative number. Received: #{income}", context: context, policy: policy.to_s }
      end
      # Normalize context to use symbol keys
      context = { income: income } if context.is_a?(Hash)
    end

    # Setup if needed
    setup_rules(policy) unless model_exists?(rule_id)

    # Import directly from XML for evaluation
    importer = DecisionAgent::Dmn::Importer.new
    result = importer.import_from_xml(
      dmn_xml_for_policy(policy),
      ruleset_name: "#{rule_id}_eval",
      created_by: 'demo_user'
    )

    evaluator = DecisionAgent::Evaluators::DmnEvaluator.new(
      model: result[:model],
      decision_id: decision_id
    )

    ctx = DecisionAgent::Context.new(context)
    evaluation = evaluator.evaluate(ctx)

    # Handle case where evaluation might be a String (error message)
    if evaluation.is_a?(String)
      return { error: evaluation, context: context, policy: policy.to_s }
    end

    {
      decision: evaluation.decision,
      confidence: evaluation.weight,
      reason: evaluation.respond_to?(:reason) ? evaluation.reason : nil,
      metadata: evaluation.respond_to?(:metadata) ? evaluation.metadata : nil,
      context: context,
      policy: policy.to_s
    }
  rescue StandardError => e
    error_message = e.message
    # Provide more helpful error message for UNIQUE hit policy
    if error_message.include?('UNIQUE hit policy') && error_message.include?('none matched')
      error_message += ". This usually means the input value doesn't match any rule conditions. " \
                       "For tax brackets, ensure income is a non-negative number. " \
                       "Received context: #{context.inspect}"
    end
    Rails.logger.error("DMN evaluation failed for #{policy}: #{error_message}")
    { error: error_message, context: context, policy: policy.to_s }
  end

  def self.model_exists?(rule_id)
    version_manager = DecisionAgent::Versioning::VersionManager.new(
      adapter: DecisionAgent::Versioning::ActiveRecordAdapter.new
    )
    version_manager.get_active_version(rule_id: rule_id).present?
  rescue
    false
  end
end

