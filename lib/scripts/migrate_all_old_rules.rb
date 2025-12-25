# Migrate all old-format rules to new DSL format

fraud_rules_migration = {
  'fraud_detection_medium' => {
    version: '1.0',
    ruleset: 'fraud_detection',
    description: 'Medium risk fraud detection',
    rules: [
      {
        id: 'medium_risk_check',
        if: {
          any: [
            {
              all: [
                { field: 'device_fingerprint_match', op: 'eq', value: false },
                { field: 'transaction_amount', op: 'gte', value: 500 }
              ]
            },
            {
              all: [
                { field: 'ip_reputation_score', op: 'lte', value: 50 },
                { field: 'transaction_amount', op: 'gte', value: 300 }
              ]
            }
          ]
        },
        then: {
          decision: 'review',
          weight: 0.8,
          reason: 'Medium fraud risk - manual review required'
        }
      }
    ]
  },
  'fraud_detection_low' => {
    version: '1.0',
    ruleset: 'fraud_detection',
    description: 'Low risk fraud detection',
    rules: [
      {
        id: 'low_risk_check',
        if: {
          any: [
            { field: 'device_fingerprint_match', op: 'eq', value: false },
            { field: 'location_match', op: 'eq', value: false },
            {
              all: [
                { field: 'ip_reputation_score', op: 'lte', value: 70 },
                { field: 'ip_reputation_score', op: 'gt', value: 50 }
              ]
            }
          ]
        },
        then: {
          decision: 'monitor',
          weight: 0.6,
          reason: 'Low fraud risk - monitor transaction'
        }
      }
    ]
  },
  'fraud_detection_safe' => {
    version: '1.0',
    ruleset: 'fraud_detection',
    description: 'Safe transaction detection',
    rules: [
      {
        id: 'safe_check',
        if: {
          all: [
            { field: 'device_fingerprint_match', op: 'eq', value: true },
            { field: 'location_match', op: 'eq', value: true },
            { field: 'ip_reputation_score', op: 'gte', value: 70 },
            { field: 'transactions_last_hour', op: 'lte', value: 5 }
          ]
        },
        then: {
          decision: 'approve',
          weight: 1.0,
          reason: 'Transaction approved - all checks passed'
        }
      }
    ]
  }
}

service = DecisionService.instance

fraud_rules_migration.each do |rule_id, new_content|
  rule = Rule.find_by(rule_id: rule_id)
  next unless rule

  active_version = rule.active_version
  next unless active_version

  content = active_version.parsed_content

  # Check if it's in old format (has 'conditions' instead of 'rules')
  if content.key?('conditions') || content.key?(:conditions)
    puts "Migrating #{rule_id} from old format..."

    # Delete old versions
    rule.rule_versions.destroy_all

    # Create new version with DSL format
    version = service.save_rule_version(
      rule_id: rule_id,
      content: new_content,
      created_by: 'system',
      changelog: 'Migrated to DSL format'
    )

    version.activate!
    puts "✓ Migrated #{rule_id}"
  else
    puts "✓ #{rule_id} already in DSL format"
  end
end

puts "\nMigration complete!"
puts "\nVerifying all rules..."

# Verify all rules
Rule.all.each do |rule|
  if rule.active_version
    content = rule.active_version.parsed_content
    has_rules = content.key?('rules') || content.key?(:rules)
    status = has_rules ? '✓' : '✗'
    format = has_rules ? 'DSL' : 'OLD'
    puts "#{status} #{rule.rule_id.ljust(35)} [#{format}]"
  end
end
