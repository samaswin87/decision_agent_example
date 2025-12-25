require 'test_helper'

class DiscountEngineUseCaseTest < ActiveSupport::TestCase
  setup do
    DiscountEngineUseCase.setup_rules
  end

  test "applies loyalty discount for gold member" do
    order = {
      customer_id: 'C123',
      customer_tier: 'gold',
      cart_total: 150.0,
      total_items: 3,
      is_first_purchase: false
    }

    result = DiscountEngineUseCase.calculate_discounts(order)

    assert result[:applied_discount].present?
    assert_equal 'percentage', result[:applied_discount][:discount_type]
    assert result[:savings] > 0
    assert result[:discounted_total] < result[:original_total]
  end

  test "applies first-time buyer discount" do
    order = {
      customer_id: 'C124',
      customer_tier: 'silver',
      cart_total: 75.0,
      total_items: 2,
      is_first_purchase: true
    }

    result = DiscountEngineUseCase.calculate_discounts(order)

    assert result[:applied_discount].present?
    assert_equal 20, result[:applied_discount][:discount_value]
    assert_match /Welcome/, result[:applied_discount][:reason]
    assert_equal 'WELCOME20', result[:applied_discount][:coupon_code]
  end

  test "applies bulk purchase discount" do
    order = {
      customer_id: 'C125',
      customer_tier: 'bronze',
      cart_total: 250.0,
      total_items: 15,
      is_first_purchase: false
    }

    result = DiscountEngineUseCase.calculate_discounts(order)

    assert result[:applied_discount].present?
    assert_equal 10, result[:applied_discount][:discount_value]
    assert_match /Bulk/, result[:applied_discount][:reason]
  end

  test "applies seasonal promo with code" do
    order = {
      customer_id: 'C126',
      customer_tier: 'silver',
      cart_total: 100.0,
      total_items: 2,
      is_first_purchase: false,
      promo_code: 'WINTER2025'
    }

    result = DiscountEngineUseCase.calculate_discounts(order)

    assert result[:applied_discount].present?
    assert_equal 'fixed', result[:applied_discount][:discount_type]
    assert_equal 25, result[:applied_discount][:discount_value]
  end

  test "applies cart threshold discount with free shipping" do
    order = {
      customer_id: 'C127',
      customer_tier: 'silver',
      cart_total: 600.0,
      total_items: 5,
      is_first_purchase: false
    }

    result = DiscountEngineUseCase.calculate_discounts(order)

    assert result[:applied_discount].present?
    assert_equal true, result[:applied_discount][:free_shipping]
    assert_match /VIP/, result[:applied_discount][:reason]
  end

  test "selects best discount when multiple apply" do
    order = {
      customer_id: 'C128',
      customer_tier: 'platinum',
      cart_total: 150.0,
      total_items: 2,
      is_first_purchase: true
    }

    result = DiscountEngineUseCase.calculate_discounts(order)

    # Should apply first-time buyer (20%) over loyalty (15%)
    assert_equal 20, result[:applied_discount][:discount_value]
    assert result[:all_available_discounts].length > 1
  end

  test "calculates correct savings for percentage discount" do
    order = {
      customer_id: 'C129',
      customer_tier: 'gold',
      cart_total: 200.0,
      total_items: 3,
      is_first_purchase: false
    }

    result = DiscountEngineUseCase.calculate_discounts(order)

    expected_savings = 200.0 * 0.15 # 15% loyalty discount
    assert_in_delta expected_savings, result[:savings], 0.01
    assert_in_delta 200.0 - expected_savings, result[:discounted_total], 0.01
  end

  test "calculates correct savings for fixed discount" do
    order = {
      customer_id: 'C130',
      customer_tier: 'silver',
      cart_total: 100.0,
      total_items: 2,
      is_first_purchase: false,
      promo_code: 'WINTER2025'
    }

    result = DiscountEngineUseCase.calculate_discounts(order)

    assert_equal 25, result[:savings]
    assert_equal 75.0, result[:discounted_total]
  end

  test "returns all available discounts" do
    order = {
      customer_id: 'C131',
      customer_tier: 'gold',
      cart_total: 600.0,
      total_items: 12,
      is_first_purchase: false
    }

    result = DiscountEngineUseCase.calculate_discounts(order)

    # Should qualify for loyalty, bulk, and threshold
    assert result[:all_available_discounts].length >= 2
  end

  test "handles no applicable discounts" do
    order = {
      customer_id: 'C132',
      customer_tier: 'bronze',
      cart_total: 25.0,
      total_items: 1,
      is_first_purchase: false
    }

    result = DiscountEngineUseCase.calculate_discounts(order)

    assert_equal 0, result[:savings]
    assert_equal result[:original_total], result[:discounted_total]
  end
end
