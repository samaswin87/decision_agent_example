# encoding: utf-8
# frozen_string_literal: true

# Comprehensive Seed Data for Decision Agent Example Application
# This file initializes all use cases with sample rules and demonstrates various scenarios

puts "\n" + "="*80
puts "SEEDING DECISION AGENT EXAMPLE APPLICATION"
puts "="*80 + "\n"

# Clear existing data
puts "🗑️  Clearing existing data..."
RuleVersion.delete_all
Rule.delete_all

# 1. Simple Loan Approval Use Case
puts "\n1️⃣  Setting up Simple Loan Approval..."
SimpleLoanUseCase.setup_rules
puts "   ✅ Simple Loan rules created"

# 2. Advanced Loan Approval Use Case
puts "\n2️⃣  Setting up Advanced Loan Approval..."
LoanApprovalUseCase.setup_rules
puts "   ✅ Advanced Loan rules created"

# 3. Fraud Detection Use Case
puts "\n3️⃣  Setting up Fraud Detection..."
FraudDetectionUseCase.setup_rules
puts "   ✅ Fraud Detection rules created"

# 4. Discount Engine Use Case
puts "\n4️⃣  Setting up Discount Engine..."
DiscountEngineUseCase.setup_rules
puts "   ✅ Discount Engine rules created"

# 5. Insurance Underwriting Use Case
puts "\n5️⃣  Setting up Insurance Underwriting..."
InsuranceUnderwritingUseCase.setup_rules
puts "   ✅ Insurance Underwriting rules created"

# 6. Content Moderation Use Case
puts "\n6️⃣  Setting up Content Moderation..."
ContentModerationUseCase.setup_rules
puts "   ✅ Content Moderation rules created"

# 7. Dynamic Pricing Use Case
puts "\n7️⃣  Setting up Dynamic Pricing..."
DynamicPricingUseCase.setup_rules
puts "   ✅ Dynamic Pricing rules created"

# 8. Recommendation Engine Use Case
puts "\n8️⃣  Setting up Recommendation Engine..."
RecommendationEngineUseCase.setup_rules
puts "   ✅ Recommendation Engine rules created"

# 9. Multi-Stage Workflow Use Case
puts "\n9️⃣  Setting up Multi-Stage Workflow..."
MultiStageWorkflowUseCase.setup_rules
puts "   ✅ Multi-Stage Workflow rules created"

# 10. Pundit Adapter Use Case
puts "\n🔟 Setting up Pundit Adapter..."
PunditAdapterUseCase.setup_rules
puts "   ✅ Pundit Adapter rules created"

# 11. Devise + CanCanCan Adapter Use Case
puts "\n1️⃣1️⃣  Setting up Devise + CanCanCan Adapter..."
DeviseCancancanAdapterUseCase.setup_rules
puts "   ✅ Devise + CanCanCan Adapter rules created"

# 12. Default Adapter Use Case
puts "\n1️⃣2️⃣  Setting up Default Adapter..."
DefaultAdapterUseCase.setup_rules
puts "   ✅ Default Adapter rules created"

# 13. Custom Adapter Use Case
puts "\n1️⃣3️⃣  Setting up Custom Adapter..."
CustomAdapterUseCase.setup_rules
puts "   ✅ Custom Adapter rules created"

# 14. Context Advanced Use Case
puts "\n1️⃣4️⃣  Setting up Context Advanced..."
ContextAdvancedUseCase.setup_rules
puts "   ✅ Context Advanced rules created"

# 15. Custom Evaluator Use Case
puts "\n1️⃣5️⃣  Setting up Custom Evaluator..."
# Custom evaluators don't need rule setup, they're Ruby classes
puts "   ✅ Custom Evaluator use case ready (no rules needed)"

# 16. Workflow Orchestration Use Case
puts "\n1️⃣6️⃣  Setting up Workflow Orchestration..."
WorkflowOrchestrationUseCase.setup_rules
puts "   ✅ Workflow Orchestration rules created"

# Summary
puts "\n" + "="*80
puts "SUMMARY"
puts "="*80

total_rules = Rule.count
total_versions = RuleVersion.count
active_versions = RuleVersion.where(status: 'active').count

puts "\n📊 Database Statistics:"
puts "   Total Rules: #{total_rules}"
puts "   Total Versions: #{total_versions}"
puts "   Active Versions: #{active_versions}"

puts "\n📋 Rules by Use Case:"
rulesets = Rule.group(:ruleset).count
rulesets.each do |ruleset, count|
  puts "   #{ruleset || 'No Ruleset'}: #{count} rules"
end

# Run sample evaluations to verify
puts "\n" + "="*80
puts "SAMPLE EVALUATIONS"
puts "="*80

# Sample 1: Loan Approval
puts "\n💰 Simple Loan - Premium Applicant"
loan_result = SimpleLoanUseCase.evaluate({
  name: "Jane Doe",
  email: "jane@example.com",
  credit_score: 780,
  annual_income: 95000,
  debt_to_income_ratio: 0.25
})
puts "   Decision: #{loan_result[:decision]}"
puts "   Confidence: #{(loan_result[:confidence] * 100).round(1)}%"

# Sample 2: Fraud Detection
puts "\n🚨 Fraud Detection - Safe Transaction"
fraud_result = FraudDetectionUseCase.evaluate({
  transaction_id: "TXN123",
  transaction_amount: 250,
  device_fingerprint_match: true,
  location_match: true,
  ip_reputation_score: 85,
  transactions_last_hour: 1,
  distance_from_last_transaction_miles: 5,
  time_since_last_transaction_minutes: 120,
  merchant_age_days: 365,
  is_international: false,
  transaction_hour: 14,
  merchant_category_mismatch: false
})
puts "   Decision: #{fraud_result[:decision]}"
puts "   Risk Level: #{fraud_result.dig(:metadata, 'risk_level')}"
puts "   Confidence: #{(fraud_result[:confidence] * 100).round(1)}%"

# Sample 3: Discount Engine
puts "\n🎁 Discount Engine - Gold Customer"
discount_result = DiscountEngineUseCase.evaluate({
  customer_id: "CUST789",
  customer_tier: "gold",
  cart_total: 150,
  total_items: 5,
  is_first_purchase: false,
  promo_code: nil
})
puts "   Decision: #{discount_result[:decision]}"
puts "   Discount Type: #{discount_result.dig(:metadata, 'discount_type')}"
puts "   Savings: $#{discount_result.dig(:metadata, 'discount_amount')}"

# Sample 4: Insurance Underwriting
puts "\n🚗 Insurance - Preferred Risk Driver"
insurance_result = InsuranceUnderwritingUseCase.evaluate({
  name: "John Smith",
  email: "john@example.com",
  driver_age: 35,
  years_licensed: 15,
  accidents_3_years: 0,
  violations_3_years: 0,
  credit_score: 750,
  annual_mileage: 10000,
  dui_history: false,
  license_suspended: false,
  sr22_required: false
})
puts "   Decision: #{insurance_result[:decision]}"
puts "   Risk Tier: #{insurance_result.dig(:metadata, 'risk_tier')}"
puts "   Annual Premium: $#{insurance_result.dig(:metadata, 'final_annual_premium')}"

# Sample 5: Content Moderation
puts "\n🛡️  Content Moderation - Safe Content"
content_result = ContentModerationUseCase.evaluate({
  content_id: "CNT456",
  user_id: "USR123",
  toxicity_score: 0.05,
  profanity_count: 0,
  spam_likelihood: 0.10,
  sexual_content_score: 0.02,
  contains_hate_speech: false,
  contains_violence: false,
  contains_csam: false,
  threat_level: 'none',
  user_reputation_score: 85,
  user_account_age_days: 365,
  user_reports_count: 0,
  external_links_count: 1,
  misinformation_indicators: 0,
  user_previous_violations_count: 0
})
puts "   Decision: #{content_result[:decision]}"
puts "   Severity: #{content_result.dig(:metadata, 'severity')}"
puts "   Action: #{content_result.dig(:metadata, 'action')}"

# Sample 6: Dynamic Pricing
puts "\n💲 Dynamic Pricing - Standard Market"
pricing_result = DynamicPricingUseCase.evaluate({
  product_id: "PROD123",
  base_price: 100.00,
  demand_level: 45,
  inventory_remaining_percentage: 55,
  inventory_count: 500,
  time_to_event_hours: 48,
  competitor_avg_price: 105.00,
  competitor_availability: 'medium',
  customer_segment: 'standard',
  days_listed: 10
})
puts "   Decision: #{pricing_result[:decision]}"
puts "   Strategy: #{pricing_result.dig(:metadata, 'pricing_strategy')}"
puts "   Final Price: $#{pricing_result.dig(:pricing, 'final_price')}"

# Sample 7: Recommendation Engine
puts "\n🎯 Recommendations - Engaged User"
recommend_result = RecommendationEngineUseCase.evaluate({
  user_id: "USR999",
  user_interaction_count: 75,
  profile_completeness: 85,
  days_since_last_visit: 1,
  is_new_user: false,
  is_holiday_season: false,
  is_user_birthday_month: false,
  special_event_active: false
})
puts "   Decision: #{recommend_result[:decision]}"
puts "   Strategy: #{recommend_result.dig(:metadata, 'strategy')}"
puts "   Recommendation Count: #{recommend_result.dig(:metadata, 'recommendation_count')}"
puts "   Engagement Level: #{recommend_result.dig(:user_profile, 'engagement_level')}"

# Sample 8: Multi-Stage Workflow - Stage 1
puts "\n📝 Multi-Stage Workflow - Low Amount Request"
workflow_result = MultiStageWorkflowUseCase.evaluate_stage(1, {
  request_id: "REQ001",
  request_type: "standard",
  request_amount: 500,
  requester_level: 3,
  risk_score: 20,
  fraud_detected: false,
  blacklisted: false,
  compliance_check: true
})
puts "   Decision: #{workflow_result[:decision]}"
puts "   Current Stage: #{workflow_result.dig(:workflow, 'current_stage_name')}"
puts "   Next Stage: #{workflow_result.dig(:workflow, 'next_stage')}"
puts "   Complete: #{workflow_result.dig(:workflow, 'is_complete')}"

puts "\n" + "="*80
puts "✅ SEEDING COMPLETE!"
puts "="*80

puts "\n🚀 Next Steps:"
puts "   1. Start the Rails server: rails server"
puts "   2. Visit http://localhost:3000"
puts "   3. Explore the demos and use cases"
puts "   4. Run performance tests: rake performance:benchmark"
puts "   5. Run load tests: rake load_test:run[medium,60,4]"
puts ""
