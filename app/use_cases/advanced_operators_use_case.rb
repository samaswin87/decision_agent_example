# Advanced Operators Use Case
# Demonstrates real-world usage of new advanced operators
# This showcases string, numeric, collection, date/time, geospatial, and statistical operators
class AdvancedOperatorsUseCase
  class << self
    def setup_rules
      # Rule 1: Email Domain Validation (String Operators)
      DecisionService.instance.save_rule_version(
        rule_id: 'email_domain_validation',
        content: {
          version: "1.0",
          ruleset: "validation",
          description: "Email validation using string operators",
          rules: [
            {
              id: "company_email_check",
              if: {
                all: [
                  { field: "email", op: "ends_with", value: "@company.com" },
                  { field: "email", op: "matches", value: "^[a-z0-9._%+-]+@company\\.com$" }
                ]
              },
              then: {
                decision: "valid_company_email",
                weight: 1.0,
                reason: "Valid company email address"
              }
            },
            {
              id: "external_email_check",
              if: {
                all: [
                  { field: "email", op: "contains", value: "@" },
                  { field: "email", op: "starts_with", value: "user" }
                ]
              },
              then: {
                decision: "external_email",
                weight: 0.8,
                reason: "External email address"
              }
            }
          ]
        },
        created_by: 'system',
        changelog: 'Email validation with string operators'
      )
      version.activate!

      # Rule 2: Age Range and Numeric Operations
      version = DecisionService.instance.save_rule_version(
        rule_id: 'age_eligibility_check',
        content: {
          version: "1.0",
          ruleset: "eligibility",
          description: "Age eligibility with numeric operators",
          rules: [
            {
              id: "adult_eligibility",
              if: {
                all: [
                  { field: "age", op: "between", value: [18, 65] },
                  { field: "age", op: "modulo", value: [2, 0] }  # Even age
                ]
              },
              then: {
                decision: "eligible",
                weight: 1.0,
                reason: "Age is within eligible range and even"
              }
            },
            {
              id: "senior_discount",
              if: {
                all: [
                  { field: "age", op: "gte", value: 65 },
                  { field: "age", op: "lte", value: 100 }
                ]
              },
              then: {
                decision: "senior_eligible",
                weight: 0.9,
                reason: "Eligible for senior discount"
              }
            }
          ]
        },
        created_by: 'system',
        changelog: 'Age eligibility with numeric operators'
      )
      version.activate!

      # Rule 3: Permission Checks (Collection Operators)
      version = DecisionService.instance.save_rule_version(
        rule_id: 'permission_access_control',
        content: {
          version: "1.0",
          ruleset: "access_control",
          description: "Permission-based access control using collection operators",
          rules: [
            {
              id: "admin_full_access",
              if: {
                all: [
                  { field: "user_permissions", op: "contains_all", value: ["read", "write", "delete", "admin"] },
                  { field: "user_roles", op: "contains_any", value: ["admin", "super_admin"] }
                ]
              },
              then: {
                decision: "full_access",
                weight: 1.0,
                reason: "User has all required permissions and admin role"
              }
            },
            {
              id: "moderator_access",
              if: {
                all: [
                  { field: "user_permissions", op: "contains_any", value: ["read", "write"] },
                  { field: "user_roles", op: "intersects", value: ["moderator", "editor"] }
                ]
              },
              then: {
                decision: "moderator_access",
                weight: 0.85,
                reason: "User has moderator permissions"
              }
            },
            {
              id: "read_only_access",
              if: {
                field: "user_permissions",
                op: "contains_any",
                value: ["read"]
              },
              then: {
                decision: "read_only",
                weight: 0.7,
                reason: "Read-only access granted"
              }
            }
          ]
        },
        created_by: 'system',
        changelog: 'Permission checks with collection operators'
      )
      version.activate!

      # Rule 4: Date/Time Based Rules
      version = DecisionService.instance.save_rule_version(
        rule_id: 'time_based_promotions',
        content: {
          version: "1.0",
          ruleset: "promotions",
          description: "Time-based promotional rules",
          rules: [
            {
              id: "weekend_sale",
              if: {
                all: [
                  { field: "current_date", op: "day_of_week", value: "saturday" },
                  { field: "current_date", op: "hour_of_day", value: { gte: 9, lte: 17 } }
                ]
              },
              then: {
                decision: "weekend_sale_active",
                weight: 1.0,
                reason: "Weekend sale is active during business hours"
              }
            },
            {
              id: "holiday_season",
              if: {
                all: [
                  { field: "current_date", op: "month", value: 12 },
                  { field: "current_date", op: "day_of_month", value: { gte: 1, lte: 31 } }
                ]
              },
              then: {
                decision: "holiday_promotion",
                weight: 0.95,
                reason: "Holiday season promotion active"
              }
            },
            {
              id: "recent_signup_bonus",
              if: {
                field: "user_signup_date",
                op: "within_days",
                value: 7
              },
              then: {
                decision: "new_user_bonus",
                weight: 0.9,
                reason: "User signed up within last 7 days"
              }
            },
            {
              id: "trial_expiring_soon",
              if: {
                field: "trial_start_date",
                op: "add_days",
                value: { days: 14, compare: "lte", target: "now" }
              },
              then: {
                decision: "trial_expiring",
                weight: 0.85,
                reason: "Trial period expiring soon"
              }
            }
          ]
        },
        created_by: 'system',
        changelog: 'Time-based promotional rules'
      )
      version.activate!

      # Rule 5: Statistical Analysis (Aggregations)
      version = DecisionService.instance.save_rule_version(
        rule_id: 'performance_monitoring',
        content: {
          version: "1.0",
          ruleset: "monitoring",
          description: "Performance monitoring with statistical operators",
          rules: [
            {
              id: "high_latency_alert",
              if: {
                field: "response_times",
                op: "percentile",
                value: { percentile: 95, threshold: 500 }
              },
              then: {
                decision: "alert_high_latency",
                weight: 0.9,
                reason: "P95 latency exceeds threshold"
              }
            },
            {
              id: "low_average_performance",
              if: {
                field: "response_times",
                op: "average",
                value: { gte: 200 }
              },
              then: {
                decision: "performance_degraded",
                weight: 0.8,
                reason: "Average response time is high"
              }
            },
            {
              id: "high_error_rate",
              if: {
                field: "error_codes",
                op: "count",
                value: { gte: 10 }
              },
              then: {
                decision: "error_threshold_exceeded",
                weight: 0.95,
                reason: "Too many errors detected"
              }
            },
            {
              id: "consistent_performance",
              if: {
                field: "response_times",
                op: "stddev",
                value: { lt: 50 }
              },
              then: {
                decision: "stable_performance",
                weight: 0.7,
                reason: "Low variance indicates stable performance"
              }
            }
          ]
        },
        created_by: 'system',
        changelog: 'Performance monitoring with statistical operators'
      )
      version.activate!

      # Rule 6: Moving Window Analysis
      version = DecisionService.instance.save_rule_version(
        rule_id: 'trend_analysis',
        content: {
          version: "1.0",
          ruleset: "analytics",
          description: "Trend analysis with moving window operators",
          rules: [
            {
              id: "increasing_trend",
              if: {
                field: "sales_data",
                op: "moving_average",
                value: { window: 7, gte: 1000 }
              },
              then: {
                decision: "positive_trend",
                weight: 0.85,
                reason: "7-day moving average shows positive trend"
              }
            },
            {
              id: "peak_detection",
              if: {
                field: "metrics",
                op: "moving_max",
                value: { window: 5, gte: 500 }
              },
              then: {
                decision: "peak_detected",
                weight: 0.9,
                reason: "Peak value detected in 5-day window"
              }
            },
            {
              id: "low_period",
              if: {
                field: "values",
                op: "moving_min",
                value: { window: 3, lte: 10 }
              },
              then: {
                decision: "low_period",
                weight: 0.75,
                reason: "Low values detected in 3-day window"
              }
            }
          ]
        },
        created_by: 'system',
        changelog: 'Trend analysis with moving window operators'
      )
      version.activate!

      # Rule 7: Geospatial Rules
      version = DecisionService.instance.save_rule_version(
        rule_id: 'delivery_zone_validation',
        content: {
          version: "1.0",
          ruleset: "delivery",
          description: "Delivery zone validation using geospatial operators",
          rules: [
            {
              id: "within_delivery_radius",
              if: {
                field: "customer_location",
                op: "within_radius",
                value: {
                  center: { lat: 40.7128, lon: -74.0060 },
                  radius: 10  # 10 km
                }
              },
              then: {
                decision: "delivery_available",
                weight: 1.0,
                reason: "Customer is within delivery radius"
              }
            },
            {
              id: "outside_delivery_zone",
              if: {
                field: "customer_location",
                op: "within_radius",
                value: {
                  center: { lat: 40.7128, lon: -74.0060 },
                  radius: 10
                },
                negate: true
              },
              then: {
                decision: "delivery_unavailable",
                weight: 0.9,
                reason: "Customer is outside delivery zone"
              }
            }
          ]
        },
        created_by: 'system',
        changelog: 'Delivery zone validation with geospatial operators'
      )
      version.activate!

      # Rule 8: Complex Combined Example
      version = DecisionService.instance.save_rule_version(
        rule_id: 'complex_eligibility_check',
        content: {
          version: "1.0",
          ruleset: "eligibility",
          description: "Complex eligibility check combining multiple operators",
          rules: [
            {
              id: "premium_eligibility",
              if: {
                all: [
                  { field: "email", op: "ends_with", value: "@company.com" },
                  { field: "age", op: "between", value: [25, 55] },
                  { field: "user_roles", op: "contains_any", value: ["employee", "contractor"] },
                  { field: "signup_date", op: "within_days", value: 365 },
                  { field: "location", op: "within_radius", value: { center: { lat: 40.7128, lon: -74.0060 }, radius: 50 } }
                ]
              },
              then: {
                decision: "premium_eligible",
                weight: 1.0,
                reason: "Meets all premium eligibility criteria"
              }
            }
          ]
        },
        created_by: 'system',
        changelog: 'Complex eligibility check with multiple operator types'
      )
      version.activate!

      puts "✓ Advanced operators use case rules created successfully"
    end

    def evaluate_email_validation(email)
      setup_rules
      DecisionService.instance.evaluate(
        rule_id: 'email_domain_validation',
        context: { email: email }
      )
    end

    def evaluate_age_eligibility(age)
      setup_rules
      DecisionService.instance.evaluate(
        rule_id: 'age_eligibility_check',
        context: { age: age }
      )
    end

    def evaluate_permissions(user_permissions, user_roles)
      setup_rules
      DecisionService.instance.evaluate(
        rule_id: 'permission_access_control',
        context: {
          user_permissions: user_permissions,
          user_roles: user_roles
        }
      )
    end

    def evaluate_time_based_promotions(current_date, user_signup_date = nil, trial_start_date = nil)
      setup_rules
      context = { current_date: current_date }
      context[:user_signup_date] = user_signup_date if user_signup_date
      context[:trial_start_date] = trial_start_date if trial_start_date
      
      DecisionService.instance.evaluate(
        rule_id: 'time_based_promotions',
        context: context
      )
    end

    def evaluate_performance_monitoring(response_times, error_codes)
      setup_rules
      DecisionService.instance.evaluate(
        rule_id: 'performance_monitoring',
        context: {
          response_times: response_times,
          error_codes: error_codes
        }
      )
    end

    def evaluate_trend_analysis(sales_data, metrics, values)
      setup_rules
      DecisionService.instance.evaluate(
        rule_id: 'trend_analysis',
        context: {
          sales_data: sales_data,
          metrics: metrics,
          values: values
        }
      )
    end

    def evaluate_delivery_zone(customer_location)
      setup_rules
      DecisionService.instance.evaluate(
        rule_id: 'delivery_zone_validation',
        context: { customer_location: customer_location }
      )
    end

    def evaluate_complex_eligibility(email, age, user_roles, signup_date, location)
      setup_rules
      DecisionService.instance.evaluate(
        rule_id: 'complex_eligibility_check',
        context: {
          email: email,
          age: age,
          user_roles: user_roles,
          signup_date: signup_date,
          location: location
        }
      )
    end

    def run_examples
      setup_rules
      
      puts "\n=== Advanced Operators Use Case Examples ===\n"
      
      # Example 1: Email Validation
      puts "1. Email Validation:"
      result = evaluate_email_validation("user@company.com")
      puts "   Input: user@company.com"
      puts "   Result: #{result[:decision]} - #{result[:explanations].first}"
      
      # Example 2: Age Eligibility
      puts "\n2. Age Eligibility:"
      result = evaluate_age_eligibility(30)
      puts "   Input: age = 30"
      puts "   Result: #{result[:decision]} - #{result[:explanations].first}"
      
      # Example 3: Permissions
      puts "\n3. Permission Check:"
      result = evaluate_permissions(["read", "write", "delete", "admin"], ["admin"])
      puts "   Input: permissions = [read, write, delete, admin], roles = [admin]"
      puts "   Result: #{result[:decision]} - #{result[:explanations].first}"
      
      # Example 4: Time-based
      puts "\n4. Time-based Promotions:"
      result = evaluate_time_based_promotions(Time.now.iso8601, (Time.now - 3.days).iso8601)
      puts "   Input: current_date = now, signup_date = 3 days ago"
      puts "   Result: #{result[:decision]} - #{result[:explanations].first}"
      
      # Example 5: Performance Monitoring
      puts "\n5. Performance Monitoring:"
      result = evaluate_performance_monitoring([100, 120, 150, 180, 200, 250, 300], ["500", "500", "404"])
      puts "   Input: response_times = [100, 120, 150, 180, 200, 250, 300], error_codes = [500, 500, 404]"
      puts "   Result: #{result[:decision]} - #{result[:explanations].first}"
      
      # Example 6: Trend Analysis
      puts "\n6. Trend Analysis:"
      result = evaluate_trend_analysis([800, 850, 900, 950, 1000, 1050, 1100], [400, 450, 500, 550, 600], [5, 8, 12])
      puts "   Input: sales_data = [800..1100], metrics = [400..600], values = [5, 8, 12]"
      puts "   Result: #{result[:decision]} - #{result[:explanations].first}"
      
      # Example 7: Delivery Zone
      puts "\n7. Delivery Zone Validation:"
      result = evaluate_delivery_zone({ lat: 40.7200, lon: -74.0000 })
      puts "   Input: location = { lat: 40.7200, lon: -74.0000 }"
      puts "   Result: #{result[:decision]} - #{result[:explanations].first}"
      
      # Example 8: Complex Eligibility
      puts "\n8. Complex Eligibility Check:"
      result = evaluate_complex_eligibility(
        "employee@company.com",
        35,
        ["employee"],
        (Time.now - 180.days).iso8601,
        { lat: 40.7200, lon: -74.0000 }
      )
      puts "   Input: email=employee@company.com, age=35, roles=[employee], signup=180 days ago, location near NYC"
      puts "   Result: #{result[:decision]} - #{result[:explanations].first}"
      
      puts "\n=== Examples Complete ===\n"
    end
  end
end

