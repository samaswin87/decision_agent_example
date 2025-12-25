# Discount Engine Use Case
# Demonstrates dynamic pricing and promotional rules
class DiscountEngineUseCase
  RULE_ID = 'discount_engine_v1'

  def self.rule_definition
    {
      rule_id: RULE_ID,
      name: 'Dynamic Discount Engine',
      description: 'Calculates appropriate discounts based on customer profile and cart',
      version: '1.0',
      conditions: [
        {
          any: [
            {
              all: [
                { fact: 'customer_tier', operator: 'equal', value: 'gold' },
                { fact: 'cart_total', operator: 'greaterThanInclusive', value: 100 }
              ]
            },
            {
              all: [
                { fact: 'customer_tier', operator: 'equal', value: 'platinum' },
                { fact: 'cart_total', operator: 'greaterThanInclusive', value: 100 }
              ]
            }
          ]
        }
      ],
      event: {
        type: 'loyalty_discount',
        params: {
          discount_type: 'percentage',
          discount_value: 15,
          reason: 'Loyalty member discount'
        }
      },
      priority: 100
    }
  end

  def self.bulk_purchase_rule
    {
      rule_id: 'discount_bulk_purchase',
      name: 'Bulk Purchase Discount',
      description: 'Discount for large quantity purchases',
      version: '1.0',
      conditions: [
        {
          all: [
            { fact: 'total_items', operator: 'greaterThanInclusive', value: 10 },
            { fact: 'cart_total', operator: 'greaterThanInclusive', value: 200 }
          ]
        }
      ],
      event: {
        type: 'bulk_discount',
        params: {
          discount_type: 'percentage',
          discount_value: 10,
          reason: 'Bulk purchase discount'
        }
      },
      priority: 90
    }
  end

  def self.first_time_buyer_rule
    {
      rule_id: 'discount_first_time',
      name: 'First Time Buyer Discount',
      description: 'Welcome discount for new customers',
      version: '1.0',
      conditions: [
        {
          all: [
            { fact: 'is_first_purchase', operator: 'equal', value: true },
            { fact: 'cart_total', operator: 'greaterThanInclusive', value: 50 }
          ]
        }
      ],
      event: {
        type: 'welcome_discount',
        params: {
          discount_type: 'percentage',
          discount_value: 20,
          reason: 'Welcome! First-time customer discount',
          coupon_code: 'WELCOME20'
        }
      },
      priority: 110
    }
  end

  def self.seasonal_promo_rule
    {
      rule_id: 'discount_seasonal',
      name: 'Seasonal Promotion',
      description: 'Holiday or seasonal promotional discount',
      version: '1.0',
      conditions: [
        {
          all: [
            { fact: 'promo_code', operator: 'equal', value: 'WINTER2025' },
            { fact: 'cart_total', operator: 'greaterThanInclusive', value: 75 }
          ]
        }
      ],
      event: {
        type: 'seasonal_discount',
        params: {
          discount_type: 'fixed',
          discount_value: 25,
          reason: 'Winter Sale 2025',
          expires_at: '2025-03-31'
        }
      },
      priority: 80
    }
  end

  def self.cart_threshold_rule
    {
      rule_id: 'discount_cart_threshold',
      name: 'Cart Threshold Discount',
      description: 'Free shipping and discount on large carts',
      version: '1.0',
      conditions: [
        {
          all: [
            { fact: 'cart_total', operator: 'greaterThanInclusive', value: 500 }
          ]
        }
      ],
      event: {
        type: 'threshold_discount',
        params: {
          discount_type: 'percentage',
          discount_value: 5,
          free_shipping: true,
          reason: 'VIP cart discount with free shipping'
        }
      },
      priority: 70
    }
  end

  # Evaluate discounts (alias for compatibility)
  def self.evaluate(order_context)
    setup_rules
    service = DecisionService.instance

    # Use simplified rule for testing
    result = service.evaluate(
      rule_id: RULE_ID,
      context: order_context
    )

    cart_total = order_context[:cart_total] || 100.0
    discount_percent = case result[:decision]
                       when 'welcome_discount' then 20
                       when 'loyalty_discount' then 15
                       when 'bulk_discount' then 10
                       else 0
                       end

    savings = cart_total * (discount_percent / 100.0)

    {
      decision: result[:decision] || 'no_discount',
      confidence: result[:confidence] || 0,
      explanations: result[:explanations] || [],
      original_total: cart_total,
      discount_percentage: discount_percent,
      savings: savings.round(2),
      discounted_total: (cart_total - savings).round(2)
    }
  end

  # Calculate all applicable discounts
  def self.calculate_discounts(order_context)
    evaluate(order_context)
  end

  # Batch evaluation for multiple orders
  def self.evaluate_batch(orders, parallel: false)
    setup_rules

    start_time = Time.current

    results = if parallel
      orders.map do |order|
        Thread.new { evaluate(order) }
      end.map(&:value)
    else
      orders.map { |order| evaluate(order) }
    end

    end_time = Time.current
    duration = end_time - start_time

    {
      results: results,
      performance: {
        total_evaluations: orders.size,
        duration_seconds: duration.round(3),
        average_per_evaluation_ms: ((duration / orders.size) * 1000).round(2),
        evaluations_per_second: (orders.size / duration).round(2),
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
      ruleset: "discount_engine",
      description: "Simplified discount engine for testing",
      rules: [
        {
          id: "first_time_buyer",
          if: {
            all: [
              { field: "is_first_purchase", op: "eq", value: true },
              { field: "cart_total", op: "gte", value: 50 }
            ]
          },
          then: {
            decision: "welcome_discount",
            weight: 1.0,
            reason: "20% first-time buyer discount"
          }
        },
        {
          id: "loyalty_discount",
          if: {
            all: [
              { field: "customer_tier", op: "eq", value: "gold" },
              { field: "cart_total", op: "gte", value: 100 }
            ]
          },
          then: {
            decision: "loyalty_discount",
            weight: 0.9,
            reason: "15% loyalty member discount"
          }
        },
        {
          id: "bulk_purchase",
          if: {
            all: [
              { field: "total_items", op: "gte", value: 10 },
              { field: "cart_total", op: "gte", value: 200 }
            ]
          },
          then: {
            decision: "bulk_discount",
            weight: 0.8,
            reason: "10% bulk purchase discount"
          }
        },
        {
          id: "no_discount",
          if: {
            all: [
              { field: "cart_total", op: "gt", value: 0 }
            ]
          },
          then: {
            decision: "no_discount",
            weight: 0.5,
            reason: "No discount applicable"
          }
        }
      ]
    }

    rule = Rule.find_or_initialize_by(rule_id: RULE_ID)
    rule.ruleset = 'discount_engine'
    rule.description = 'Discount engine rules'
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

  def self.select_best_discount(discounts, cart_total)
    return nil if discounts.empty?

    discounts.max_by do |discount|
      calculate_savings(cart_total, discount)
    end
  end

  def self.calculate_savings(cart_total, discount)
    return 0 unless discount

    if discount[:discount_type] == 'percentage'
      cart_total * (discount[:discount_value] / 100.0)
    else
      discount[:discount_value]
    end
  end

  def self.calculate_final_total(cart_total, discount)
    return cart_total unless discount

    savings = calculate_savings(cart_total, discount)
    cart_total - savings
  end
end
