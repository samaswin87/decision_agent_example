# Migrate old-format discount rules to new DSL format

discount_rules = ['discount_first_time', 'discount_seasonal', 'discount_cart_threshold']

discount_rules.each do |rule_id|
  # Check if rule exists and needs migration
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

    # Create new version with DSL format based on rule_id
    new_content = case rule_id
    when 'discount_first_time'
      {
        version: '1.0',
        ruleset: 'discount_engine',
        description: 'First-time buyer discount',
        rules: [
          {
            id: 'first_time_buyer_check',
            if: {
              all: [
                { field: 'is_first_purchase', op: 'eq', value: true },
                { field: 'cart_total', op: 'gte', value: 50 }
              ]
            },
            then: {
              decision: 'welcome_discount',
              weight: 1.0,
              reason: '20% first-time customer discount'
            }
          }
        ]
      }
    when 'discount_seasonal'
      {
        version: '1.0',
        ruleset: 'discount_engine',
        description: 'Seasonal promotional discount',
        rules: [
          {
            id: 'seasonal_promo_check',
            if: {
              all: [
                { field: 'promo_code', op: 'eq', value: 'WINTER2025' },
                { field: 'cart_total', op: 'gte', value: 75 }
              ]
            },
            then: {
              decision: 'seasonal_discount',
              weight: 0.9,
              reason: 'Winter Sale 2025 - $25 off'
            }
          }
        ]
      }
    when 'discount_cart_threshold'
      {
        version: '1.0',
        ruleset: 'discount_engine',
        description: 'Cart threshold discount with free shipping',
        rules: [
          {
            id: 'cart_threshold_check',
            if: {
              all: [
                { field: 'cart_total', op: 'gte', value: 500 }
              ]
            },
            then: {
              decision: 'threshold_discount',
              weight: 0.7,
              reason: 'VIP cart discount (5%) with free shipping'
            }
          }
        ]
      }
    end

    service = DecisionService.instance
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

puts "Migration complete!"
