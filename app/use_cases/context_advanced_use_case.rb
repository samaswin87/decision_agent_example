# Context Advanced Use Case
# Demonstrates advanced usage of DecisionAgent::Context class
# Shows context transformation, validation, and enrichment
class ContextAdvancedUseCase
  RULE_ID = 'context_advanced_example'

  class << self
    def setup_rules
      service = DecisionService.instance

      rule = Rule.find_or_initialize_by(rule_id: RULE_ID)
      rule.ruleset = 'context_advanced'
      rule.description = 'Advanced Context usage examples'
      rule.status = 'active'
      rule.save!

      unless rule.active_version
        version = service.save_rule_version(
          rule_id: RULE_ID,
          content: {
            version: "1.0",
            ruleset: "context_advanced",
            description: "Advanced context manipulation examples",
            rules: [
              {
                id: "enriched_context_check",
                if: {
                  all: [
                    { field: "user_tier", op: "in", value: ["gold", "platinum"] },
                    { field: "account_age_days", op: "gte", value: 365 },
                    { field: "total_spent", op: "gte", value: 10000 }
                  ]
                },
                then: {
                  decision: "premium_benefits",
                  weight: 1.0,
                  reason: "User qualifies for premium benefits",
                  metadata: {
                    discount_percentage: 15,
                    free_shipping: true,
                    priority_support: true
                  }
                }
              },
              {
                id: "context_validation",
                if: {
                  all: [
                    { field: "email", op: "present", value: true },
                    { field: "phone", op: "present", value: true },
                    { field: "address", op: "present", value: true }
                  ]
                },
                then: {
                  decision: "profile_complete",
                  weight: 0.9,
                  reason: "User profile is complete"
                }
              }
            ]
          },
          created_by: 'system',
          changelog: 'Initial context advanced example'
        )
        version.activate!
      end

      puts "✓ Context advanced use case rules created successfully"
    end

    # Demonstrate context transformation
    def transform_context(raw_context)
      setup_rules

      # Create a Context object and transform it
      ctx = DecisionAgent::Context.new(raw_context)

      # Enrich context with computed fields
      enriched = ctx.to_h.merge(
        account_age_days: calculate_account_age(raw_context[:signup_date]),
        total_spent: calculate_total_spent(raw_context[:user_id]),
        user_tier: determine_user_tier(raw_context[:user_id])
      )

      # Create new context with enriched data
      enriched_ctx = DecisionAgent::Context.new(enriched)

      # Evaluate with enriched context
      service = DecisionService.instance
      result = service.evaluate(
        rule_id: RULE_ID,
        context: enriched_ctx.to_h
      )

      {
        original_context: raw_context,
        enriched_context: enriched,
        result: result,
        transformations_applied: [
          "account_age_days calculated",
          "total_spent aggregated",
          "user_tier determined"
        ]
      }
    end

    # Demonstrate context validation
    def validate_context(context_hash)
      setup_rules

      ctx = DecisionAgent::Context.new(context_hash)
      ctx_hash = ctx.to_h

      # Validate required fields
      required_fields = [:email, :phone, :address]
      missing_fields = required_fields.reject { |field| ctx_hash[field].present? || ctx_hash[field.to_s].present? }

      if missing_fields.any?
        return {
          valid: false,
          missing_fields: missing_fields,
          context: context_hash
        }
      end

      # Evaluate with validated context
      service = DecisionService.instance
      result = service.evaluate(
        rule_id: RULE_ID,
        context: ctx_hash
      )

      {
        valid: true,
        context: ctx_hash,
        result: result
      }
    end

    # Demonstrate context chaining
    def chain_context_transformations(context_hash)
      setup_rules

      # Start with base context
      ctx1 = DecisionAgent::Context.new(context_hash)

      # First transformation: add computed fields
      transformed1 = ctx1.to_h.merge(
        full_name: "#{ctx1[:first_name]} #{ctx1[:last_name]}",
        initials: "#{ctx1[:first_name]&.first}#{ctx1[:last_name]&.first}"
      )
      ctx2 = DecisionAgent::Context.new(transformed1)

      # Second transformation: add derived metrics
      transformed2 = ctx2.to_h.merge(
        engagement_score: calculate_engagement(ctx2.to_h),
        risk_score: calculate_risk(ctx2.to_h)
      )
      ctx3 = DecisionAgent::Context.new(transformed2)

      # Final evaluation
      service = DecisionService.instance
      result = service.evaluate(
        rule_id: RULE_ID,
        context: ctx3.to_h
      )

      {
        stages: [
          { name: "base", context: ctx1.to_h },
          { name: "name_enrichment", context: ctx2.to_h },
          { name: "metrics_enrichment", context: ctx3.to_h }
        ],
        final_result: result
      }
    end

    # Demonstrate context filtering
    def filter_context(context_hash, allowed_keys)
      setup_rules

      ctx = DecisionAgent::Context.new(context_hash)

      # Filter to only allowed keys
      filtered = ctx.to_h.select { |k, v| allowed_keys.include?(k.to_sym) }

      filtered_ctx = DecisionAgent::Context.new(filtered)

      service = DecisionService.instance
      result = service.evaluate(
        rule_id: RULE_ID,
        context: filtered_ctx.to_h
      )

      {
        original_keys: context_hash.keys,
        filtered_keys: filtered.keys,
        filtered_context: filtered,
        result: result
      }
    end

    private

    def calculate_account_age(signup_date)
      return 0 unless signup_date
      (Time.now - Time.parse(signup_date.to_s)) / 86400
    end

    def calculate_total_spent(user_id)
      # Mock calculation - in real app, query database
      rand(5000..50000)
    end

    def determine_user_tier(user_id)
      # Mock determination - in real app, query database
      ['bronze', 'silver', 'gold', 'platinum'].sample
    end

    def calculate_engagement(context)
      # Mock engagement calculation
      base_score = context[:login_count] || 0
      interaction_bonus = (context[:interaction_count] || 0) * 2
      (base_score + interaction_bonus) / 100.0
    end

    def calculate_risk(context)
      # Mock risk calculation
      risk_factors = [
        context[:failed_logins] || 0,
        context[:suspicious_activity] ? 10 : 0,
        context[:account_age_days] ? (365 - context[:account_age_days]) / 365.0 : 0.5
      ]
      risk_factors.sum / risk_factors.length
    end
  end
end

