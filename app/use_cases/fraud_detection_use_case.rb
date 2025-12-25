# Fraud Detection Use Case
# Demonstrates real-time risk assessment and fraud prevention
class FraudDetectionUseCase
  RULE_ID = 'fraud_detection_v1'

  def self.rule_definition
    {
      rule_id: RULE_ID,
      name: 'Transaction Fraud Detection',
      description: 'Identifies potentially fraudulent transactions',
      version: '1.0',
      conditions: [
        {
          any: [
            # High velocity transactions
            {
              all: [
                { fact: 'transactions_last_hour', operator: 'greaterThan', value: 5 },
                { fact: 'total_amount_last_hour', operator: 'greaterThan', value: 1000 }
              ]
            },
            # Unusual location
            {
              all: [
                { fact: 'location_distance_from_usual', operator: 'greaterThan', value: 500 },
                { fact: 'time_since_last_transaction', operator: 'lessThan', value: 3600 }
              ]
            },
            # High risk amount
            {
              all: [
                { fact: 'transaction_amount', operator: 'greaterThan', value: 5000 },
                { fact: 'is_new_merchant', operator: 'equal', value: true }
              ]
            }
          ]
        }
      ],
      event: {
        type: 'fraud_alert_high',
        params: {
          risk_level: 'high',
          action: 'block',
          require_verification: true,
          alert_team: true,
          message: 'Transaction blocked due to high fraud risk'
        }
      },
      priority: 200
    }
  end

  def self.medium_risk_rule
    {
      rule_id: 'fraud_detection_medium',
      name: 'Medium Risk Transaction',
      description: 'Requires additional verification',
      version: '1.0',
      conditions: [
        {
          any: [
            {
              all: [
                { fact: 'transaction_amount', operator: 'greaterThan', value: 1000 },
                { fact: 'device_fingerprint_match', operator: 'equal', value: false }
              ]
            },
            {
              all: [
                { fact: 'ip_reputation_score', operator: 'lessThan', value: 50 },
                { fact: 'transaction_amount', operator: 'greaterThan', value: 500 }
              ]
            },
            {
              all: [
                { fact: 'transaction_hour', operator: 'lessThan', value: 6 },
                { fact: 'transaction_amount', operator: 'greaterThan', value: 2000 },
                { fact: 'is_unusual_time', operator: 'equal', value: true }
              ]
            }
          ]
        }
      ],
      event: {
        type: 'fraud_alert_medium',
        params: {
          risk_level: 'medium',
          action: 'review',
          require_verification: true,
          verification_method: '2fa',
          message: 'Additional verification required'
        }
      },
      priority: 150
    }
  end

  def self.low_risk_rule
    {
      rule_id: 'fraud_detection_low',
      name: 'Low Risk Transaction Monitoring',
      description: 'Monitor for patterns',
      version: '1.0',
      conditions: [
        {
          any: [
            {
              all: [
                { fact: 'transaction_amount', operator: 'greaterThan', value: 500 },
                { fact: 'is_first_international', operator: 'equal', value: true }
              ]
            },
            {
              all: [
                { fact: 'merchant_category_change', operator: 'equal', value: true },
                { fact: 'transaction_amount', operator: 'greaterThan', value: 300 }
              ]
            }
          ]
        }
      ],
      event: {
        type: 'fraud_alert_low',
        params: {
          risk_level: 'low',
          action: 'monitor',
          require_verification: false,
          log_for_analysis: true,
          message: 'Transaction approved with monitoring'
        }
      },
      priority: 100
    }
  end

  def self.safe_transaction_rule
    {
      rule_id: 'fraud_detection_safe',
      name: 'Safe Transaction',
      description: 'Low risk, approved automatically',
      version: '1.0',
      conditions: [
        {
          all: [
            { fact: 'device_fingerprint_match', operator: 'equal', value: true },
            { fact: 'location_match', operator: 'equal', value: true },
            { fact: 'transaction_amount', operator: 'lessThanInclusive', value: 500 },
            { fact: 'ip_reputation_score', operator: 'greaterThanInclusive', value: 70 }
          ]
        }
      ],
      event: {
        type: 'transaction_safe',
        params: {
          risk_level: 'safe',
          action: 'approve',
          require_verification: false,
          message: 'Transaction approved'
        }
      },
      priority: 50
    }
  end

  # Evaluate transaction for fraud (alias for compatibility)
  def self.evaluate(transaction_data)
    setup_rules
    service = DecisionService.instance
    enriched_data = enrich_transaction_data(transaction_data)

    # Use simplified rule for testing
    result = service.evaluate(
      rule_id: RULE_ID,
      context: enriched_data
    )

    {
      transaction_id: transaction_data[:transaction_id],
      timestamp: Time.current,
      decision: result[:decision] || 'approve',
      confidence: result[:confidence] || 0,
      explanations: result[:explanations] || [],
      risk_level: case result[:decision]
                  when 'block' then 'high'
                  when 'review' then 'medium'
                  else 'safe'
                  end
    }
  end

  # Evaluate transaction for fraud
  def self.evaluate_transaction(transaction_data)
    evaluate(transaction_data)
  end

  # Batch evaluation for multiple transactions
  def self.evaluate_batch(transactions, parallel: true)
    setup_rules

    start_time = Time.current

    results = if parallel
      transactions.map do |txn|
        Thread.new { evaluate_transaction(txn) }
      end.map(&:value)
    else
      transactions.map { |txn| evaluate_transaction(txn) }
    end

    end_time = Time.current
    duration = end_time - start_time

    {
      results: results,
      performance: {
        total_evaluations: transactions.size,
        duration_seconds: duration.round(3),
        average_per_evaluation_ms: ((duration / transactions.size) * 1000).round(2),
        evaluations_per_second: (transactions.size / duration).round(2),
        parallel: parallel,
        started_at: start_time,
        completed_at: end_time
      }
    }
  end

  def self.setup_rules
    service = DecisionService.instance

    # Simplified DSL-compatible rule for testing
    simple_rule = {
      version: "1.0",
      ruleset: "fraud_detection",
      description: "Simplified fraud detection for testing",
      rules: [
        {
          id: "high_risk_fraud",
          if: {
            any: [
              { field: "transaction_amount", op: "gt", value: 5000 },
              { field: "transactions_last_hour", op: "gt", value: 5 }
            ]
          },
          then: {
            decision: "block",
            weight: 1.0,
            reason: "High risk transaction detected"
          }
        },
        {
          id: "medium_risk_fraud",
          if: {
            any: [
              { field: "transaction_amount", op: "gt", value: 1000 },
              { field: "location_distance_from_usual", op: "gt", value: 100 }
            ]
          },
          then: {
            decision: "review",
            weight: 0.7,
            reason: "Medium risk - additional verification required"
          }
        },
        {
          id: "safe_transaction",
          if: {
            all: [
              { field: "transaction_amount", op: "lte", value: 500 },
              { field: "device_fingerprint_match", op: "eq", value: true }
            ]
          },
          then: {
            decision: "approve",
            weight: 1.0,
            reason: "Safe transaction approved"
          }
        }
      ]
    }

    rule = Rule.find_or_initialize_by(rule_id: RULE_ID)
    rule.ruleset = 'fraud_detection'
    rule.description = 'Fraud detection rules'
    rule.status = 'active'
    rule.save!

    unless rule.active_version
      service.save_rule_version(
        rule_id: RULE_ID,
        content: simple_rule,
        created_by: 'system',
        changelog: 'Initial simplified version for testing'
      )
      rule.rule_versions.first&.activate!
    end
  end

  private

  def self.enrich_transaction_data(data)
    # Add calculated fields and enrichments
    data.merge(
      time_since_last_transaction: calculate_time_since_last(data),
      location_distance_from_usual: calculate_location_distance(data),
      is_unusual_time: unusual_transaction_time?(data),
      merchant_category_change: merchant_category_changed?(data)
    )
  end

  def self.calculate_time_since_last(data)
    # Placeholder - would query actual transaction history
    data[:time_since_last_transaction] || 7200
  end

  def self.calculate_location_distance(data)
    # Placeholder - would calculate actual distance
    data[:location_distance_from_usual] || 0
  end

  def self.unusual_transaction_time?(data)
    hour = data[:transaction_hour] || Time.current.hour
    hour < 6 || hour > 23
  end

  def self.merchant_category_changed?(data)
    # Placeholder - would check transaction history
    false
  end

  def self.format_fraud_result(decision, original_data, enriched_data)
    {
      transaction_id: original_data[:transaction_id],
      timestamp: Time.current,
      decision: decision&.dig(:event, :params, :action) || 'approve',
      risk_level: decision&.dig(:event, :params, :risk_level) || 'safe',
      details: decision&.dig(:event, :params) || {},
      rule_triggered: decision&.dig(:rule_id),
      risk_factors: identify_risk_factors(enriched_data),
      requires_action: decision&.dig(:event, :params, :require_verification) || false
    }
  end

  def self.identify_risk_factors(data)
    factors = []
    factors << 'high_velocity' if data[:transactions_last_hour].to_i > 5
    factors << 'unusual_location' if data[:location_distance_from_usual].to_i > 500
    factors << 'new_merchant' if data[:is_new_merchant]
    factors << 'unusual_time' if data[:is_unusual_time]
    factors << 'device_mismatch' unless data[:device_fingerprint_match]
    factors
  end
end
