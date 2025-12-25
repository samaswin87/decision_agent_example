require 'test_helper'

class FraudDetectionUseCaseTest < ActiveSupport::TestCase
  setup do
    FraudDetectionUseCase.setup_rules
  end

  test "blocks high-risk transaction with multiple rapid transactions" do
    transaction = {
      transaction_id: 'TXN001',
      transaction_amount: 800,
      transactions_last_hour: 8,
      total_amount_last_hour: 2500,
      device_fingerprint_match: true,
      location_match: true,
      ip_reputation_score: 75
    }

    result = FraudDetectionUseCase.evaluate_transaction(transaction)

    assert_equal 'block', result[:decision]
    assert_equal 'high', result[:risk_level]
    assert result[:requires_action]
    assert result[:risk_factors].include?('high_velocity')
  end

  test "blocks transaction from unusual location" do
    transaction = {
      transaction_id: 'TXN002',
      transaction_amount: 500,
      transactions_last_hour: 1,
      total_amount_last_hour: 500,
      location_distance_from_usual: 1000,
      time_since_last_transaction: 1800,
      device_fingerprint_match: true,
      ip_reputation_score: 70
    }

    result = FraudDetectionUseCase.evaluate_transaction(transaction)

    assert_equal 'block', result[:decision]
    assert_equal 'high', result[:risk_level]
    assert result[:risk_factors].include?('unusual_location')
  end

  test "blocks high amount to new merchant" do
    transaction = {
      transaction_id: 'TXN003',
      transaction_amount: 6000,
      is_new_merchant: true,
      transactions_last_hour: 1,
      device_fingerprint_match: true,
      location_match: true,
      ip_reputation_score: 80
    }

    result = FraudDetectionUseCase.evaluate_transaction(transaction)

    assert_equal 'block', result[:decision]
    assert_equal 'high', result[:risk_level]
    assert result[:risk_factors].include?('new_merchant')
  end

  test "requires verification for medium-risk transaction" do
    transaction = {
      transaction_id: 'TXN004',
      transaction_amount: 1500,
      device_fingerprint_match: false,
      transactions_last_hour: 1,
      location_match: true,
      ip_reputation_score: 65
    }

    result = FraudDetectionUseCase.evaluate_transaction(transaction)

    assert_equal 'review', result[:decision]
    assert_equal 'medium', result[:risk_level]
    assert result[:requires_action]
    assert result[:risk_factors].include?('device_mismatch')
  end

  test "requires verification for low IP reputation" do
    transaction = {
      transaction_id: 'TXN005',
      transaction_amount: 600,
      ip_reputation_score: 45,
      device_fingerprint_match: true,
      location_match: true,
      transactions_last_hour: 1
    }

    result = FraudDetectionUseCase.evaluate_transaction(transaction)

    assert_equal 'review', result[:decision]
    assert_equal 'medium', result[:risk_level]
  end

  test "monitors unusual time transaction" do
    transaction = {
      transaction_id: 'TXN006',
      transaction_amount: 2500,
      transaction_hour: 3,
      is_unusual_time: true,
      device_fingerprint_match: true,
      location_match: true,
      ip_reputation_score: 70
    }

    result = FraudDetectionUseCase.evaluate_transaction(transaction)

    # Could be medium or low risk depending on other factors
    assert_includes ['review', 'monitor'], result[:decision]
    assert result[:risk_factors].include?('unusual_time')
  end

  test "monitors first international transaction" do
    transaction = {
      transaction_id: 'TXN007',
      transaction_amount: 600,
      is_first_international: true,
      device_fingerprint_match: true,
      location_match: true,
      ip_reputation_score: 70,
      transactions_last_hour: 1
    }

    result = FraudDetectionUseCase.evaluate_transaction(transaction)

    assert_equal 'monitor', result[:decision]
    assert_equal 'low', result[:risk_level]
    refute result[:requires_action]
  end

  test "approves safe transaction" do
    transaction = {
      transaction_id: 'TXN008',
      transaction_amount: 250,
      device_fingerprint_match: true,
      location_match: true,
      ip_reputation_score: 85,
      transactions_last_hour: 1
    }

    result = FraudDetectionUseCase.evaluate_transaction(transaction)

    assert_equal 'approve', result[:decision]
    assert_equal 'safe', result[:risk_level]
    refute result[:requires_action]
    assert_empty result[:risk_factors]
  end

  test "evaluates batch of transactions sequentially" do
    transactions = [
      {
        transaction_id: 'TXN101',
        transaction_amount: 100,
        device_fingerprint_match: true,
        location_match: true,
        ip_reputation_score: 80
      },
      {
        transaction_id: 'TXN102',
        transaction_amount: 7000,
        is_new_merchant: true,
        device_fingerprint_match: true,
        location_match: true,
        ip_reputation_score: 70
      }
    ]

    results = FraudDetectionUseCase.evaluate_batch(transactions, parallel: false)

    assert_equal 2, results.length
    assert_equal 'approve', results[0][:decision]
    assert_equal 'block', results[1][:decision]
  end

  test "evaluates batch of transactions in parallel" do
    transactions = 5.times.map do |i|
      {
        transaction_id: "TXN20#{i}",
        transaction_amount: 200,
        device_fingerprint_match: true,
        location_match: true,
        ip_reputation_score: 80
      }
    end

    results = FraudDetectionUseCase.evaluate_batch(transactions, parallel: true)

    assert_equal 5, results.length
    results.each do |result|
      assert_equal 'approve', result[:decision]
    end
  end

  test "includes transaction details in result" do
    transaction = {
      transaction_id: 'TXN999',
      transaction_amount: 300,
      device_fingerprint_match: true,
      location_match: true,
      ip_reputation_score: 75
    }

    result = FraudDetectionUseCase.evaluate_transaction(transaction)

    assert_equal 'TXN999', result[:transaction_id]
    assert result[:timestamp].present?
    assert result[:rule_triggered].present?
  end

  test "identifies multiple risk factors" do
    transaction = {
      transaction_id: 'TXN010',
      transaction_amount: 1000,
      transactions_last_hour: 6,
      total_amount_last_hour: 3000,
      device_fingerprint_match: false,
      is_new_merchant: true,
      location_distance_from_usual: 600,
      ip_reputation_score: 50
    }

    result = FraudDetectionUseCase.evaluate_transaction(transaction)

    assert result[:risk_factors].include?('high_velocity')
    assert result[:risk_factors].include?('unusual_location')
    assert result[:risk_factors].include?('new_merchant')
    assert result[:risk_factors].include?('device_mismatch')
  end
end
