# Insurance Underwriting Use Case
# Evaluates insurance applications with multi-factor risk assessment
class InsuranceUnderwritingUseCase
  class << self
    def setup_rules
      # Rule 1: Auto Insurance - Preferred Risk
      DecisionService.instance.save_rule_version(
        rule_id: 'auto_insurance_preferred',
        content: {
          conditions: {
            all: [
              { fact: 'driver_age', operator: 'gte', value: 25 },
              { fact: 'driver_age', operator: 'lte', value: 65 },
              { fact: 'years_licensed', operator: 'gte', value: 5 },
              { fact: 'accidents_3_years', operator: 'lte', value: 0 },
              { fact: 'violations_3_years', operator: 'lte', value: 0 },
              { fact: 'credit_score', operator: 'gte', value: 700 },
              { fact: 'annual_mileage', operator: 'lte', value: 12000 }
            ]
          },
          decision: 'approved',
          priority: 100,
          metadata: {
            risk_tier: 'preferred',
            annual_premium: 800,
            discount_percentage: 25,
            coverage_limit: 500000,
            deductible_options: [250, 500, 1000],
            features: ['accident_forgiveness', 'vanishing_deductible', 'rental_coverage']
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Initial auto insurance preferred risk rule'
      )
      DecisionService.instance.activate_version('auto_insurance_preferred', 1)

      # Rule 2: Auto Insurance - Standard Risk
      DecisionService.instance.save_rule_version(
        rule_id: 'auto_insurance_standard',
        content: {
          conditions: {
            all: [
              { fact: 'driver_age', operator: 'gte', value: 21 },
              { fact: 'years_licensed', operator: 'gte', value: 2 },
              { fact: 'accidents_3_years', operator: 'lte', value: 1 },
              { fact: 'violations_3_years', operator: 'lte', value: 2 },
              { fact: 'credit_score', operator: 'gte', value: 600 }
            ]
          },
          decision: 'approved',
          priority: 80,
          metadata: {
            risk_tier: 'standard',
            annual_premium: 1400,
            discount_percentage: 10,
            coverage_limit: 300000,
            deductible_options: [500, 1000, 2500],
            features: ['roadside_assistance', 'rental_coverage'],
            surcharge_per_accident: 200,
            surcharge_per_violation: 100
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Auto insurance standard risk rule'
      )
      DecisionService.instance.activate_version('auto_insurance_standard', 1)

      # Rule 3: Auto Insurance - High Risk
      DecisionService.instance.save_rule_version(
        rule_id: 'auto_insurance_high_risk',
        content: {
          conditions: {
            all: [
              { fact: 'driver_age', operator: 'gte', value: 18 },
              { fact: 'years_licensed', operator: 'gte', value: 1 }
            ],
            any: [
              { fact: 'accidents_3_years', operator: 'gte', value: 2 },
              { fact: 'violations_3_years', operator: 'gte', value: 3 },
              { fact: 'dui_history', operator: 'eq', value: true },
              { fact: 'credit_score', operator: 'lt', value: 600 }
            ]
          },
          decision: 'approved_high_risk',
          priority: 60,
          metadata: {
            risk_tier: 'high_risk',
            annual_premium: 3500,
            discount_percentage: 0,
            coverage_limit: 100000,
            deductible_options: [1000, 2500],
            features: ['basic_liability'],
            required_monitoring: 'telematics_device',
            review_period_months: 6
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Auto insurance high risk rule'
      )
      DecisionService.instance.activate_version('auto_insurance_high_risk', 1)

      # Rule 4: Auto Insurance - Rejection
      DecisionService.instance.save_rule_version(
        rule_id: 'auto_insurance_rejection',
        content: {
          conditions: {
            any: [
              { fact: 'driver_age', operator: 'lt', value: 18 },
              { fact: 'years_licensed', operator: 'lt', value: 1 },
              { fact: 'license_suspended', operator: 'eq', value: true },
              { fact: 'sr22_required', operator: 'eq', value: true },
              {
                all: [
                  { fact: 'dui_history', operator: 'eq', value: true },
                  { fact: 'accidents_3_years', operator: 'gte', value: 2 }
                ]
              }
            ]
          },
          decision: 'rejected',
          priority: 200,
          metadata: {
            risk_tier: 'uninsurable',
            rejection_reasons: [],
            reconsideration_period_months: 12,
            alternative_options: ['state_assigned_risk_pool', 'non_standard_carrier_referral']
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Auto insurance rejection rule'
      )
      DecisionService.instance.activate_version('auto_insurance_rejection', 1)

      puts "✓ Insurance underwriting rules created successfully"
    end

    def evaluate(context)
      rule_ids = [
        'auto_insurance_rejection',
        'auto_insurance_preferred',
        'auto_insurance_standard',
        'auto_insurance_high_risk'
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
      result ||= { decision: 'rejected', metadata: {} }

      # Calculate final premium with surcharges
      if result[:decision] == 'approved' || result[:decision] == 'approved_high_risk'
        metadata = result[:metadata] || {}
        base_premium = metadata['annual_premium'] || 0

        # Add surcharges for accidents and violations
        surcharge = 0
        surcharge += (context[:accidents_3_years] || 0) * (metadata['surcharge_per_accident'] || 0)
        surcharge += (context[:violations_3_years] || 0) * (metadata['surcharge_per_violation'] || 0)

        final_premium = base_premium + surcharge
        discount = final_premium * ((metadata['discount_percentage'] || 0) / 100.0)

        result[:metadata] = metadata.merge(
          'base_premium' => base_premium,
          'surcharges' => surcharge,
          'total_discount' => discount.round(2),
          'final_annual_premium' => (final_premium - discount).round(2),
          'monthly_payment' => ((final_premium - discount) / 12.0).round(2)
        )
      elsif result[:decision] == 'rejected'
        # Add specific rejection reasons
        reasons = []
        reasons << 'Underage driver (must be 18+)' if (context[:driver_age] || 0) < 18
        reasons << 'Insufficient driving experience' if (context[:years_licensed] || 0) < 1
        reasons << 'License currently suspended' if context[:license_suspended]
        reasons << 'SR-22 filing required' if context[:sr22_required]
        reasons << 'Multiple DUI incidents with recent accidents' if context[:dui_history] && (context[:accidents_3_years] || 0) >= 2

        result[:metadata] = (result[:metadata] || {}).merge('rejection_reasons' => reasons)
      end

      # Add applicant info
      result[:applicant] = {
        name: context[:name],
        email: context[:email],
        driver_age: context[:driver_age],
        years_licensed: context[:years_licensed]
      }

      result
    end

    def evaluate_batch(applications, parallel: false)
      setup_rules

      start_time = Time.current

      results = if parallel
        applications.map do |app|
          Thread.new { evaluate(app) }
        end.map(&:value)
      else
        applications.map { |app| evaluate(app) }
      end

      end_time = Time.current
      duration = end_time - start_time

      {
        results: results,
        performance: {
          total_evaluations: applications.size,
          duration_seconds: duration.round(3),
          average_per_evaluation_ms: ((duration / applications.size) * 1000).round(2),
          evaluations_per_second: (applications.size / duration).round(2),
          parallel: parallel,
          started_at: start_time,
          completed_at: end_time
        }
      }
    end
  end
end
