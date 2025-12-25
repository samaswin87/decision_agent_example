# Dynamic Pricing Use Case
# Real-time pricing optimization based on multiple market factors
class DynamicPricingUseCase
  class << self
    def setup_rules
      # Rule 1: Surge Pricing - High Demand Period
      DecisionService.instance.save_rule_version(
        rule_id: 'pricing_surge',
        content: {
          conditions: {
            all: [
              { fact: 'demand_level', operator: 'gte', value: 80 },
              { fact: 'inventory_remaining_percentage', operator: 'lte', value: 20 },
              { fact: 'competitor_availability', operator: 'eq', value: 'low' }
            ]
          },
          decision: 'surge_pricing',
          priority: 200,
          metadata: {
            pricing_strategy: 'surge',
            price_multiplier: 2.5,
            max_price_cap_multiplier: 3.0,
            dynamic_adjustment: true,
            surge_factors: {
              demand_premium: 50,
              scarcity_premium: 40,
              competition_premium: 35
            },
            estimated_conversion_rate: 0.35,
            profit_margin_target: 0.65,
            message_to_customer: 'High demand pricing in effect'
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Surge pricing for peak demand periods'
      )
      DecisionService.instance.activate_version('pricing_surge', 1)

      # Rule 2: Premium Pricing - Optimal Conditions
      DecisionService.instance.save_rule_version(
        rule_id: 'pricing_premium',
        content: {
          conditions: {
            all: [
              { fact: 'demand_level', operator: 'gte', value: 60 },
              { fact: 'demand_level', operator: 'lt', value: 80 },
              { fact: 'inventory_remaining_percentage', operator: 'gte', value: 20 },
              { fact: 'inventory_remaining_percentage', operator: 'lte', value: 40 },
              { fact: 'time_to_event_hours', operator: 'lte', value: 24 }
            ]
          },
          decision: 'premium_pricing',
          priority: 150,
          metadata: {
            pricing_strategy: 'premium',
            price_multiplier: 1.75,
            max_price_cap_multiplier: 2.0,
            dynamic_adjustment: true,
            premium_factors: {
              urgency_premium: 25,
              demand_premium: 30,
              limited_supply_premium: 20
            },
            estimated_conversion_rate: 0.55,
            profit_margin_target: 0.50,
            message_to_customer: 'Premium pricing - limited availability'
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Premium pricing for strong demand'
      )
      DecisionService.instance.activate_version('pricing_premium', 1)

      # Rule 3: Standard Pricing - Normal Conditions
      DecisionService.instance.save_rule_version(
        rule_id: 'pricing_standard',
        content: {
          conditions: {
            all: [
              { fact: 'demand_level', operator: 'gte', value: 30 },
              { fact: 'demand_level', operator: 'lt', value: 60 },
              { fact: 'inventory_remaining_percentage', operator: 'gte', value: 40 },
              { fact: 'inventory_remaining_percentage', operator: 'lte', value: 70 }
            ]
          },
          decision: 'standard_pricing',
          priority: 100,
          metadata: {
            pricing_strategy: 'standard',
            price_multiplier: 1.0,
            max_price_cap_multiplier: 1.0,
            dynamic_adjustment: false,
            estimated_conversion_rate: 0.70,
            profit_margin_target: 0.35,
            message_to_customer: 'Standard pricing'
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Standard pricing for normal market conditions'
      )
      DecisionService.instance.activate_version('pricing_standard', 1)

      # Rule 4: Promotional Pricing - Boost Sales
      DecisionService.instance.save_rule_version(
        rule_id: 'pricing_promotional',
        content: {
          conditions: {
            any: [
              {
                all: [
                  { fact: 'demand_level', operator: 'lt', value: 30 },
                  { fact: 'inventory_remaining_percentage', operator: 'gte', value: 70 }
                ]
              },
              {
                all: [
                  { fact: 'time_to_event_hours', operator: 'lte', value: 6 },
                  { fact: 'inventory_remaining_percentage', operator: 'gte', value: 50 }
                ]
              },
              {
                all: [
                  { fact: 'customer_segment', operator: 'eq', value: 'vip' },
                  { fact: 'demand_level', operator: 'lt', value: 50 }
                ]
              }
            ]
          },
          decision: 'promotional_pricing',
          priority: 80,
          metadata: {
            pricing_strategy: 'promotional',
            price_multiplier: 0.75,
            max_price_cap_multiplier: 0.75,
            dynamic_adjustment: true,
            discount_percentage: 25,
            estimated_conversion_rate: 0.85,
            profit_margin_target: 0.20,
            message_to_customer: 'Special promotional pricing!',
            promo_urgency: 'Limited time offer'
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Promotional pricing to boost conversions'
      )
      DecisionService.instance.activate_version('pricing_promotional', 1)

      # Rule 5: Clearance Pricing - Maximum Liquidation
      DecisionService.instance.save_rule_version(
        rule_id: 'pricing_clearance',
        content: {
          conditions: {
            any: [
              {
                all: [
                  { fact: 'time_to_event_hours', operator: 'lte', value: 2 },
                  { fact: 'inventory_remaining_percentage', operator: 'gte', value: 30 }
                ]
              },
              {
                all: [
                  { fact: 'demand_level', operator: 'lt', value: 15 },
                  { fact: 'inventory_remaining_percentage', operator: 'gte', value: 80 },
                  { fact: 'days_listed', operator: 'gte', value: 30 }
                ]
              }
            ]
          },
          decision: 'clearance_pricing',
          priority: 60,
          metadata: {
            pricing_strategy: 'clearance',
            price_multiplier: 0.50,
            max_price_cap_multiplier: 0.50,
            dynamic_adjustment: false,
            discount_percentage: 50,
            estimated_conversion_rate: 0.95,
            profit_margin_target: 0.05,
            message_to_customer: 'CLEARANCE SALE - Final opportunity!',
            promo_urgency: 'Last chance - grab it now!'
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Clearance pricing for inventory liquidation'
      )
      DecisionService.instance.activate_version('pricing_clearance', 1)

      puts "✓ Dynamic pricing rules created successfully"
    end

    def evaluate(context)
      rule_ids = [
        'pricing_surge',
        'pricing_premium',
        'pricing_standard',
        'pricing_promotional',
        'pricing_clearance'
      ]

      # Evaluate against the first matching rule (in priority order)
      result = nil
      rule_ids.each do |rule_id|
        temp_result = DecisionService.instance.evaluate(rule_id: rule_id, context: context)
        if temp_result && !temp_result[:error]
          result = temp_result
          break
        end
      end
      result ||= { decision: 'standard', metadata: {} }

      # Calculate final pricing
      base_price = context[:base_price] || 100.0
      metadata = result[:metadata] || {}

      price_multiplier = metadata['price_multiplier'] || 1.0
      calculated_price = base_price * price_multiplier

      # Apply customer segment adjustments
      if context[:customer_segment] == 'vip'
        calculated_price *= 0.95 # 5% VIP discount
      elsif context[:customer_segment] == 'new'
        calculated_price *= 0.90 # 10% new customer discount
      end

      # Calculate competitor-based adjustments
      if context[:competitor_avg_price]
        competitor_diff = ((calculated_price - context[:competitor_avg_price]) / context[:competitor_avg_price]) * 100

        # Adjust if we're more than 20% above competitor average
        if competitor_diff > 20
          calculated_price = context[:competitor_avg_price] * 1.15 # Stay competitive at +15%
          metadata['competitive_adjustment_applied'] = true
        end
      end

      # Round to 2 decimals
      final_price = calculated_price.round(2)

      # Calculate expected revenue
      estimated_conversion = metadata['estimated_conversion_rate'] || 0.5
      inventory_count = context[:inventory_count] || 0
      expected_units_sold = (inventory_count * estimated_conversion).round
      expected_revenue = (final_price * expected_units_sold).round(2)

      result[:pricing] = {
        base_price: base_price,
        final_price: final_price,
        price_change_amount: (final_price - base_price).round(2),
        price_change_percentage: (((final_price - base_price) / base_price) * 100).round(2),
        estimated_conversion_rate: estimated_conversion,
        expected_units_sold: expected_units_sold,
        expected_revenue: expected_revenue,
        profit_margin_target: metadata['profit_margin_target'],
        customer_message: metadata['message_to_customer']
      }

      # Add market analysis
      result[:market_analysis] = {
        demand_level: context[:demand_level],
        inventory_status: "#{context[:inventory_remaining_percentage]}% remaining",
        time_sensitivity: "#{context[:time_to_event_hours]} hours until event",
        competitive_position: context[:competitor_availability],
        customer_segment: context[:customer_segment]
      }

      result
    end

    def evaluate_batch(pricing_scenarios, parallel: false)
      setup_rules

      start_time = Time.current

      results = if parallel
        pricing_scenarios.map do |scenario|
          Thread.new { evaluate(scenario) }
        end.map(&:value)
      else
        pricing_scenarios.map { |scenario| evaluate(scenario) }
      end

      end_time = Time.current
      duration = end_time - start_time

      {
        results: results,
        performance: {
          total_evaluations: pricing_scenarios.size,
          duration_seconds: duration.round(3),
          average_per_evaluation_ms: ((duration / pricing_scenarios.size) * 1000).round(2),
          evaluations_per_second: (pricing_scenarios.size / duration).round(2),
          parallel: parallel,
          started_at: start_time,
          completed_at: end_time
        }
      }
    end
  end
end
