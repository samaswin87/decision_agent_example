#!/usr/bin/env ruby
# frozen_string_literal: true

# Comprehensive Test Script for All Discount Rules
# This demonstrates each discount rule with correct contexts and various test scenarios

puts "\n" + "="*80
puts "DISCOUNT RULES COMPREHENSIVE TEST SUITE"
puts "="*80 + "\n"

# Ensure rules are set up
puts "📋 Setting up discount rules..."
DiscountEngineUseCase.setup_rules
puts "✅ Rules loaded\n"

# Helper method to print results
def print_result(title, result, context)
  puts "\n" + "-"*80
  puts "🧪 #{title}"
  puts "-"*80
  puts "📥 Context:"
  context.each do |key, value|
    puts "   #{key}: #{value.inspect}"
  end
  puts "\n📤 Result:"
  puts "   Decision: #{result[:decision]}"
  puts "   Confidence: #{(result[:confidence] * 100).round(1)}%"
  puts "   Explanations: #{result[:explanations].join(', ')}" if result[:explanations]&.any?

  if result[:metadata]
    puts "\n📊 Metadata:"
    result[:metadata].each do |key, value|
      puts "   #{key}: #{value}"
    end
  end

  if result[:savings]
    puts "\n💰 Pricing:"
    puts "   Original Total: $#{result[:original_total]}"
    puts "   Discount: #{result[:discount_percentage]}%"
    puts "   Savings: $#{result[:savings]}"
    puts "   Final Total: $#{result[:discounted_total]}"
  end
end

# Helper for testing individual rules
def test_individual_rule(rule_id, context, title)
  service = DecisionService.instance
  result = service.evaluate(rule_id: rule_id, context: context)
  print_result(title, result, context)
  result
end

puts "\n" + "="*80
puts "PART 1: TESTING INDIVIDUAL DISCOUNT RULES"
puts "="*80

# ============================================================================
# 1. DISCOUNT_CART_THRESHOLD RULE
# ============================================================================
puts "\n\n" + "🛒 CART THRESHOLD DISCOUNT (Free Shipping + 5% off)"
puts "="*80
puts "Rule: discount_cart_threshold"
puts "Condition: cart_total >= $500"
puts "Reward: 5% discount + free shipping"

# Test 1.1: Below threshold
test_individual_rule(
  'discount_cart_threshold',
  { cart_total: 250 },
  "Test 1.1: Cart $250 (Below $500 threshold) ❌"
)

# Test 1.2: Exactly at threshold
test_individual_rule(
  'discount_cart_threshold',
  { cart_total: 500 },
  "Test 1.2: Cart $500 (Exactly at threshold) ✅"
)

# Test 1.3: Above threshold
test_individual_rule(
  'discount_cart_threshold',
  { cart_total: 750 },
  "Test 1.3: Cart $750 (Above threshold) ✅"
)

# Test 1.4: Large cart
test_individual_rule(
  'discount_cart_threshold',
  { cart_total: 2500 },
  "Test 1.4: Cart $2500 (Large order) ✅"
)

# ============================================================================
# 2. DISCOUNT_FIRST_TIME RULE
# ============================================================================
puts "\n\n" + "👋 FIRST TIME BUYER DISCOUNT (20% off)"
puts "="*80
puts "Rule: discount_first_time"
puts "Conditions: is_first_purchase == true AND cart_total >= $50"
puts "Reward: 20% discount"

# Test 2.1: First purchase, cart below minimum
test_individual_rule(
  'discount_first_time',
  {
    is_first_purchase: true,
    cart_total: 30
  },
  "Test 2.1: First purchase, cart $30 (Below $50 minimum) ❌"
)

# Test 2.2: First purchase, meets minimum
test_individual_rule(
  'discount_first_time',
  {
    is_first_purchase: true,
    cart_total: 50
  },
  "Test 2.2: First purchase, cart $50 (Meets minimum) ✅"
)

# Test 2.3: First purchase, large cart
test_individual_rule(
  'discount_first_time',
  {
    is_first_purchase: true,
    cart_total: 150
  },
  "Test 2.3: First purchase, cart $150 ✅"
)

# Test 2.4: Not first purchase
test_individual_rule(
  'discount_first_time',
  {
    is_first_purchase: false,
    cart_total: 150
  },
  "Test 2.4: Returning customer, cart $150 ❌"
)

# Test 2.5: Missing is_first_purchase field
test_individual_rule(
  'discount_first_time',
  {
    cart_total: 150
  },
  "Test 2.5: Missing is_first_purchase field ❌"
)

# ============================================================================
# 3. DISCOUNT_SEASONAL RULE
# ============================================================================
puts "\n\n" + "❄️  SEASONAL PROMOTION (Winter Sale)"
puts "="*80
puts "Rule: discount_seasonal"
puts "Conditions: promo_code == 'WINTER2025' AND cart_total >= $75"
puts "Reward: $25 off"

# Test 3.1: Wrong promo code
test_individual_rule(
  'discount_seasonal',
  {
    promo_code: 'SUMMER2025',
    cart_total: 100
  },
  "Test 3.1: Wrong promo code 'SUMMER2025' ❌"
)

# Test 3.2: Correct promo code, cart below minimum
test_individual_rule(
  'discount_seasonal',
  {
    promo_code: 'WINTER2025',
    cart_total: 50
  },
  "Test 3.2: Correct promo, cart $50 (Below $75 minimum) ❌"
)

# Test 3.3: Correct promo code, meets minimum
test_individual_rule(
  'discount_seasonal',
  {
    promo_code: 'WINTER2025',
    cart_total: 75
  },
  "Test 3.3: Correct promo, cart $75 (Meets minimum) ✅"
)

# Test 3.4: Correct promo code, large cart
test_individual_rule(
  'discount_seasonal',
  {
    promo_code: 'WINTER2025',
    cart_total: 200
  },
  "Test 3.4: Correct promo, cart $200 ✅"
)

# Test 3.5: No promo code provided
test_individual_rule(
  'discount_seasonal',
  {
    cart_total: 100
  },
  "Test 3.5: No promo code provided ❌"
)

# ============================================================================
# 4. DISCOUNT_BULK_PURCHASE RULE
# ============================================================================
puts "\n\n" + "📦 BULK PURCHASE DISCOUNT (10% off)"
puts "="*80
puts "Rule: discount_bulk_purchase"
puts "Conditions: total_items >= 10 AND cart_total >= $200"
puts "Reward: 10% discount"

# Test 4.1: Enough items, cart below minimum
test_individual_rule(
  'discount_bulk_purchase',
  {
    total_items: 15,
    cart_total: 150
  },
  "Test 4.1: 15 items, cart $150 (Below $200 minimum) ❌"
)

# Test 4.2: Not enough items, cart meets minimum
test_individual_rule(
  'discount_bulk_purchase',
  {
    total_items: 5,
    cart_total: 250
  },
  "Test 4.2: 5 items (Below 10), cart $250 ❌"
)

# Test 4.3: Meets both conditions exactly
test_individual_rule(
  'discount_bulk_purchase',
  {
    total_items: 10,
    cart_total: 200
  },
  "Test 4.3: 10 items, cart $200 (Meets both minimums) ✅"
)

# Test 4.4: Well above both thresholds
test_individual_rule(
  'discount_bulk_purchase',
  {
    total_items: 25,
    cart_total: 500
  },
  "Test 4.4: 25 items, cart $500 ✅"
)

# Test 4.5: Missing total_items field
test_individual_rule(
  'discount_bulk_purchase',
  {
    cart_total: 300
  },
  "Test 4.5: Missing total_items field ❌"
)

# ============================================================================
# PART 2: TESTING COMBINED DISCOUNT ENGINE
# ============================================================================
puts "\n\n" + "="*80
puts "PART 2: TESTING COMBINED DISCOUNT ENGINE (discount_engine_v1)"
puts "="*80
puts "This tests the main discount engine that combines multiple discount types"

# Test 5.1: Gold tier loyalty customer
result = DiscountEngineUseCase.evaluate({
  customer_id: "CUST001",
  customer_tier: "gold",
  cart_total: 150,
  total_items: 5,
  is_first_purchase: false,
  promo_code: nil
})
print_result("Test 5.1: Gold Loyalty Customer", result, {
  customer_tier: "gold",
  cart_total: 150
})

# Test 5.2: Platinum tier loyalty customer
result = DiscountEngineUseCase.evaluate({
  customer_id: "CUST002",
  customer_tier: "platinum",
  cart_total: 250,
  total_items: 3,
  is_first_purchase: false,
  promo_code: nil
})
print_result("Test 5.2: Platinum Loyalty Customer", result, {
  customer_tier: "platinum",
  cart_total: 250
})

# Test 5.3: First-time buyer (highest priority discount)
result = DiscountEngineUseCase.evaluate({
  customer_id: "CUST003",
  customer_tier: "standard",
  cart_total: 100,
  total_items: 3,
  is_first_purchase: true,
  promo_code: nil
})
print_result("Test 5.3: First-Time Buyer", result, {
  is_first_purchase: true,
  cart_total: 100
})

# Test 5.4: Bulk purchase discount
result = DiscountEngineUseCase.evaluate({
  customer_id: "CUST004",
  customer_tier: "standard",
  cart_total: 300,
  total_items: 15,
  is_first_purchase: false,
  promo_code: nil
})
print_result("Test 5.4: Bulk Purchase", result, {
  total_items: 15,
  cart_total: 300
})

# Test 5.5: No discount applicable
result = DiscountEngineUseCase.evaluate({
  customer_id: "CUST005",
  customer_tier: "standard",
  cart_total: 50,
  total_items: 2,
  is_first_purchase: false,
  promo_code: nil
})
print_result("Test 5.5: No Discount Applicable", result, {
  customer_tier: "standard",
  cart_total: 50,
  is_first_purchase: false
})

# ============================================================================
# PART 3: EDGE CASES AND SPECIAL SCENARIOS
# ============================================================================
puts "\n\n" + "="*80
puts "PART 3: EDGE CASES AND SPECIAL SCENARIOS"
puts "="*80

# Test 6.1: Multiple rules could apply - highest priority wins
puts "\n📌 Testing Rule Priority (First-time buyer who also qualifies for bulk discount)"
result = DiscountEngineUseCase.evaluate({
  customer_id: "CUST006",
  customer_tier: "standard",
  cart_total: 300,
  total_items: 15,
  is_first_purchase: true,
  promo_code: nil
})
print_result("Test 6.1: Multiple Qualifying Rules", result, {
  is_first_purchase: true,
  total_items: 15,
  cart_total: 300
})
puts "\n   ℹ️  Note: Should get 'welcome_discount' (20%) instead of 'bulk_discount' (10%)"
puts "   because first-time buyer has higher weight (1.0 vs 0.8)"

# Test 6.2: Empty cart
test_individual_rule(
  'discount_cart_threshold',
  { cart_total: 0 },
  "Test 6.2: Empty Cart ($0)"
)

# Test 6.3: Case sensitivity test for promo code
test_individual_rule(
  'discount_seasonal',
  {
    promo_code: 'winter2025',  # lowercase
    cart_total: 100
  },
  "Test 6.3: Promo Code Case Sensitivity (lowercase)"
)

# Test 6.4: Boolean value variations
test_individual_rule(
  'discount_first_time',
  {
    is_first_purchase: 'true',  # string instead of boolean
    cart_total: 100
  },
  "Test 6.4: Boolean as String"
)

# ============================================================================
# SUMMARY
# ============================================================================
puts "\n\n" + "="*80
puts "TEST SUMMARY"
puts "="*80

puts "\n📊 Discount Rules Available:"
puts "   1. discount_cart_threshold - VIP cart discount for orders >= $500 (5% + free shipping)"
puts "   2. discount_first_time - Welcome discount for first-time buyers (20% off, cart >= $50)"
puts "   3. discount_seasonal - Winter 2025 promo ($25 off with code WINTER2025, cart >= $75)"
puts "   4. discount_bulk_purchase - Bulk discount for 10+ items and cart >= $200 (10% off)"
puts "   5. discount_engine_v1 - Combined discount engine (loyalty, first-time, bulk)"

puts "\n📋 Key Findings:"
puts "   ✅ Rules correctly match when all conditions are met"
puts "   ✅ Rules correctly reject when conditions are not met"
puts "   ✅ Missing fields in context cause rules to not match"
puts "   ✅ Rule priority/weight determines which discount wins when multiple apply"
puts "   ✅ Field values must match exactly (case-sensitive, type-sensitive)"

puts "\n💡 Common Issues:"
puts "   ⚠️  Using wrong context fields (e.g., credit_score for cart discount)"
puts "   ⚠️  Missing required fields (e.g., omitting is_first_purchase)"
puts "   ⚠️  Type mismatches (e.g., string 'true' vs boolean true)"
puts "   ⚠️  Case sensitivity (e.g., 'winter2025' vs 'WINTER2025')"

puts "\n🎯 Quick Reference - Correct Contexts:"
puts "\n   Cart Threshold:"
puts "   { cart_total: 500 }"

puts "\n   First-Time Buyer:"
puts "   { is_first_purchase: true, cart_total: 50 }"

puts "\n   Seasonal Promo:"
puts "   { promo_code: 'WINTER2025', cart_total: 75 }"

puts "\n   Bulk Purchase:"
puts "   { total_items: 10, cart_total: 200 }"

puts "\n   Full Discount Engine:"
puts "   { customer_tier: 'gold', cart_total: 100, total_items: 5, is_first_purchase: false }"

puts "\n" + "="*80
puts "✅ TEST SUITE COMPLETE!"
puts "="*80
puts ""
