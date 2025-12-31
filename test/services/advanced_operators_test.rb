require 'test_helper'

class AdvancedOperatorsTest < ActiveSupport::TestCase
  setup do
    @service = DecisionService.instance
    @service.clear_cache
  end

  teardown do
    @service.clear_cache
  end

  # STRING OPERATORS
  test "contains operator matches substring" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "error_detection",
          if: { field: "message", op: "contains", value: "error" },
          then: { decision: "alert", weight: 0.9, reason: "Error found" }
        }
      ]
    }

    rule = create_rule_with_content("contains_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "contains_test",
      context: { message: "An error occurred in the system" }
    )

    assert_equal "alert", result[:decision]
  end

  test "starts_with operator matches prefix" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "error_code",
          if: { field: "code", op: "starts_with", value: "ERR" },
          then: { decision: "error_handler", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("starts_with_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "starts_with_test",
      context: { code: "ERR_404" }
    )

    assert_equal "error_handler", result[:decision]
  end

  test "ends_with operator matches suffix" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "pdf_processor",
          if: { field: "filename", op: "ends_with", value: ".pdf" },
          then: { decision: "process_pdf", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("ends_with_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "ends_with_test",
      context: { filename: "document.pdf" }
    )

    assert_equal "process_pdf", result[:decision]
  end

  test "matches operator works with regex" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "email_validation",
          if: { field: "email", op: "matches", value: "^[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}$" },
          then: { decision: "valid_email", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("matches_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "matches_test",
      context: { email: "user@example.com" }
    )

    assert_equal "valid_email", result[:decision]
  end

  # NUMERIC OPERATORS
  test "between operator matches range" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "age_check",
          if: { field: "age", op: "between", value: [18, 65] },
          then: { decision: "eligible", weight: 0.9 }
        }
      ]
    }

    rule = create_rule_with_content("between_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "between_test",
      context: { age: 30 }
    )

    assert_equal "eligible", result[:decision]
  end

  test "modulo operator works for even numbers" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "even_check",
          if: { field: "number", op: "modulo", value: [2, 0] },
          then: { decision: "even", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("modulo_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "modulo_test",
      context: { number: 10 }
    )

    assert_equal "even", result[:decision]
  end

  # COLLECTION OPERATORS
  test "contains_all operator matches when all elements present" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "permission_check",
          if: { field: "permissions", op: "contains_all", value: ["read", "write"] },
          then: { decision: "full_access", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("contains_all_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "contains_all_test",
      context: { permissions: ["read", "write", "execute"] }
    )

    assert_equal "full_access", result[:decision]
  end

  test "contains_any operator matches when any element present" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "priority_check",
          if: { field: "tags", op: "contains_any", value: ["urgent", "critical"] },
          then: { decision: "prioritize", weight: 0.95 }
        }
      ]
    }

    rule = create_rule_with_content("contains_any_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "contains_any_test",
      context: { tags: ["normal", "urgent"] }
    )

    assert_equal "prioritize", result[:decision]
  end

  test "intersects operator matches common elements" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "role_check",
          if: { field: "user_roles", op: "intersects", value: ["admin", "moderator"] },
          then: { decision: "has_elevated_role", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("intersects_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "intersects_test",
      context: { user_roles: ["user", "moderator"] }
    )

    assert_equal "has_elevated_role", result[:decision]
  end

  # STATISTICAL AGGREGATIONS
  test "sum operator calculates array sum" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "total_check",
          if: { field: "amounts", op: "sum", value: { gte: 100 } },
          then: { decision: "free_shipping", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("sum_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "sum_test",
      context: { amounts: [25, 30, 50] }
    )

    assert_equal "free_shipping", result[:decision]
  end

  test "average operator calculates mean" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "latency_check",
          if: { field: "response_times", op: "average", value: { lt: 200 } },
          then: { decision: "acceptable", weight: 0.9 }
        }
      ]
    }

    rule = create_rule_with_content("average_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "average_test",
      context: { response_times: [150, 180, 190] }
    )

    assert_equal "acceptable", result[:decision]
  end

  test "count operator counts array elements" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "error_threshold",
          if: { field: "errors", op: "count", value: { gte: 5 } },
          then: { decision: "alert", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("count_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "count_test",
      context: { errors: ["err1", "err2", "err3", "err4", "err5"] }
    )

    assert_equal "alert", result[:decision]
  end

  # DATE/TIME OPERATORS
  test "before_date operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "expiration_check",
          if: { field: "expires_at", op: "before_date", value: "2025-12-31" },
          then: { decision: "not_expired", weight: 0.8 }
        }
      ]
    }

    rule = create_rule_with_content("before_date_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "before_date_test",
      context: { expires_at: "2025-06-01" }
    )

    assert_equal "not_expired", result[:decision]
  end

  test "within_days operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "upcoming_event",
          if: { field: "event_date", op: "within_days", value: 7 },
          then: { decision: "upcoming", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("within_days_test", rule_content)
    
    event_date = (Time.now + (3 * 24 * 60 * 60)).strftime("%Y-%m-%d")
    result = @service.evaluate(
      rule_id: "within_days_test",
      context: { event_date: event_date }
    )

    assert_equal "upcoming", result[:decision]
  end

  # GEOSPATIAL OPERATORS
  test "within_radius operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "delivery_zone",
          if: {
            field: "location",
            op: "within_radius",
            value: { center: { lat: 40.7128, lon: -74.0060 }, radius: 10 }
          },
          then: { decision: "nearby", weight: 0.9 }
        }
      ]
    }

    rule = create_rule_with_content("within_radius_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "within_radius_test",
      context: { location: { lat: 40.7200, lon: -74.0000 } }
    )

    assert_equal "nearby", result[:decision]
  end

  # MATHEMATICAL OPERATORS
  test "sqrt operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "square_root",
          if: { field: "number", op: "sqrt", value: 3.0 },
          then: { decision: "square_root", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("sqrt_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "sqrt_test",
      context: { number: 9 }
    )

    assert_equal "square_root", result[:decision]
  end

  test "abs operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "absolute",
          if: { field: "value", op: "abs", value: 5 },
          then: { decision: "absolute", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("abs_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "abs_test",
      context: { value: -5 }
    )

    assert_equal "absolute", result[:decision]
  end

  test "sin operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "zero_angle",
          if: { field: "angle", op: "sin", value: 0.0 },
          then: { decision: "zero_angle", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("sin_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "sin_test",
      context: { angle: 0 }
    )

    assert_equal "zero_angle", result[:decision]
  end

  test "cos operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "zero_angle",
          if: { field: "angle", op: "cos", value: 1.0 },
          then: { decision: "zero_angle", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("cos_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "cos_test",
      context: { angle: 0 }
    )

    assert_equal "zero_angle", result[:decision]
  end

  test "power operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "power_match",
          if: { field: "base", op: "power", value: [2, 4] },
          then: { decision: "power_match", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("power_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "power_test",
      context: { base: 2 }
    )

    assert_equal "power_match", result[:decision]
  end

  test "round operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "rounded",
          if: { field: "value", op: "round", value: 3 },
          then: { decision: "rounded", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("round_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "round_test",
      context: { value: 3.4 }
    )

    assert_equal "rounded", result[:decision]
  end

  test "floor operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "floored",
          if: { field: "value", op: "floor", value: 3 },
          then: { decision: "floored", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("floor_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "floor_test",
      context: { value: 3.9 }
    )

    assert_equal "floored", result[:decision]
  end

  test "ceil operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "ceiled",
          if: { field: "value", op: "ceil", value: 4 },
          then: { decision: "ceiled", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("ceil_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "ceil_test",
      context: { value: 3.1 }
    )

    assert_equal "ceiled", result[:decision]
  end

  test "min operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "min_found",
          if: { field: "numbers", op: "min", value: 1 },
          then: { decision: "min_found", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("min_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "min_test",
      context: { numbers: [3, 1, 5, 2] }
    )

    assert_equal "min_found", result[:decision]
  end

  test "max operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "max_found",
          if: { field: "numbers", op: "max", value: 5 },
          then: { decision: "max_found", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("max_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "max_test",
      context: { numbers: [3, 1, 5, 2] }
    )

    assert_equal "max_found", result[:decision]
  end

  test "median operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "median_match",
          if: { field: "scores", op: "median", value: 50 },
          then: { decision: "median_match", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("median_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "median_test",
      context: { scores: [40, 50, 60] }
    )

    assert_equal "median_match", result[:decision]
  end

  test "stddev operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "low_variance",
          if: { field: "values", op: "stddev", value: { lt: 5 } },
          then: { decision: "low_variance", weight: 0.9 }
        }
      ]
    }

    rule = create_rule_with_content("stddev_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "stddev_test",
      context: { values: [10, 11, 12, 13, 14] }
    )

    assert_equal "low_variance", result[:decision]
  end

  test "percentile operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "p95_ok",
          if: { field: "latencies", op: "percentile", value: { percentile: 95, threshold: 200 } },
          then: { decision: "p95_ok", weight: 0.95 }
        }
      ]
    }

    rule = create_rule_with_content("percentile_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "percentile_test",
      context: { latencies: [100, 120, 150, 180, 190, 200, 210] }
    )

    assert_equal "p95_ok", result[:decision]
  end

  test "duration_seconds operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "within_hour",
          if: { field: "start_time", op: "duration_seconds", value: { end: "now", max: 3600 } },
          then: { decision: "within_hour", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("duration_seconds_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "duration_seconds_test",
      context: { start_time: (Time.now - 1800).iso8601 }
    )

    assert_equal "within_hour", result[:decision]
  end

  test "hour_of_day operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "business_hours",
          if: { field: "timestamp", op: "hour_of_day", value: { gte: 9, lte: 17 } },
          then: { decision: "business_hours", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("hour_of_day_test", rule_content)
    
    time = Time.new(2025, 1, 1, 14, 0, 0)
    result = @service.evaluate(
      rule_id: "hour_of_day_test",
      context: { timestamp: time.iso8601 }
    )

    assert_equal "business_hours", result[:decision]
  end

  test "length operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "valid_length",
          if: { field: "description", op: "length", value: { min: 10, max: 500 } },
          then: { decision: "valid_length", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("length_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "length_test",
      context: { description: "This is a valid description" }
    )

    assert_equal "valid_length", result[:decision]
  end

  # MOVING WINDOW OPERATORS
  test "moving_sum operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "match",
          if: { field: "values", op: "moving_sum", value: { window: 3, gte: 25 } },
          then: { decision: "match", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("moving_sum_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "moving_sum_test",
      context: { values: [10, 10, 10, 5] }
    )

    assert_equal "match", result[:decision]
  end

  test "moving_max operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "high_peak",
          if: { field: "metrics", op: "moving_max", value: { window: 5, gte: 100 } },
          then: { decision: "high_peak", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("moving_max_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "moving_max_test",
      context: { metrics: [80, 85, 90, 95, 100, 105] }
    )

    assert_equal "high_peak", result[:decision]
  end

  test "moving_min operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "low_dip",
          if: { field: "values", op: "moving_min", value: { window: 3, lte: 5 } },
          then: { decision: "low_dip", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("moving_min_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "moving_min_test",
      context: { values: [10, 5, 8, 12] }
    )

    assert_equal "low_dip", result[:decision]
  end

  # TIME COMPONENT EXTRACTION
  test "day_of_month operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "mid_month",
          if: { field: "date", op: "day_of_month", value: 15 },
          then: { decision: "mid_month", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("day_of_month_test", rule_content)
    
    time = Time.new(2025, 1, 15, 12, 0, 0)
    result = @service.evaluate(
      rule_id: "day_of_month_test",
      context: { date: time.iso8601 }
    )

    assert_equal "mid_month", result[:decision]
  end

  test "month operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "december",
          if: { field: "event_date", op: "month", value: 12 },
          then: { decision: "december", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("month_test", rule_content)
    
    time = Time.new(2025, 12, 25, 12, 0, 0)
    result = @service.evaluate(
      rule_id: "month_test",
      context: { event_date: time.iso8601 }
    )

    assert_equal "december", result[:decision]
  end

  test "year operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "current_year",
          if: { field: "timestamp", op: "year", value: 2025 },
          then: { decision: "current_year", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("year_test", rule_content)
    
    time = Time.new(2025, 6, 15, 12, 0, 0)
    result = @service.evaluate(
      rule_id: "year_test",
      context: { timestamp: time.iso8601 }
    )

    assert_equal "current_year", result[:decision]
  end

  test "week_of_year operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "first_week",
          if: { field: "date", op: "week_of_year", value: 1 },
          then: { decision: "first_week", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("week_of_year_test", rule_content)
    
    # January 1st is typically week 1
    time = Time.new(2025, 1, 1, 12, 0, 0)
    result = @service.evaluate(
      rule_id: "week_of_year_test",
      context: { date: time.iso8601 }
    )

    assert_equal "first_week", result[:decision]
  end

  # DATE ARITHMETIC
  test "subtract_days operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "not_urgent",
          if: { field: "deadline", op: "subtract_days", value: { days: 1, compare: "gt", target: "now" } },
          then: { decision: "not_urgent", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("subtract_days_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "subtract_days_test",
      context: { deadline: (Time.now + (2 * 86_400)).iso8601 }
    )

    assert_equal "not_urgent", result[:decision]
  end

  test "add_hours operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "past_2h",
          if: { field: "start", op: "add_hours", value: { hours: 2, compare: "lt", target: "now" } },
          then: { decision: "past_2h", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("add_hours_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "add_hours_test",
      context: { start: (Time.now - 7200).iso8601 }
    )

    assert_equal "past_2h", result[:decision]
  end

  test "subtract_hours operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "within_hour",
          if: { field: "deadline", op: "subtract_hours", value: { hours: 1, compare: "gt", target: "now" } },
          then: { decision: "within_hour", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("subtract_hours_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "subtract_hours_test",
      context: { deadline: (Time.now + 3600).iso8601 }
    )

    assert_equal "within_hour", result[:decision]
  end

  test "add_minutes operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "past_30min",
          if: { field: "start", op: "add_minutes", value: { minutes: 30, compare: "lt", target: "now" } },
          then: { decision: "past_30min", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("add_minutes_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "add_minutes_test",
      context: { start: (Time.now - 1800).iso8601 }
    )

    assert_equal "past_30min", result[:decision]
  end

  test "subtract_minutes operator works" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "within_15min",
          if: { field: "deadline", op: "subtract_minutes", value: { minutes: 15, compare: "gt", target: "now" } },
          then: { decision: "within_15min", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("subtract_minutes_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "subtract_minutes_test",
      context: { deadline: (Time.now + 900).iso8601 }
    )

    assert_equal "within_15min", result[:decision]
  end

  # COMPLEX COMBINATIONS
  test "combines multiple new operators" do
    rule_content = {
      version: "1.0",
      ruleset: "test",
      rules: [
        {
          id: "complex_rule",
          if: {
            all: [
              { field: "email", op: "ends_with", value: "@company.com" },
              { field: "age", op: "between", value: [18, 65] },
              { field: "roles", op: "contains_any", value: ["admin", "manager"] }
            ]
          },
          then: { decision: "approve", weight: 1.0 }
        }
      ]
    }

    rule = create_rule_with_content("complex_test", rule_content)
    
    result = @service.evaluate(
      rule_id: "complex_test",
      context: {
        email: "user@company.com",
        age: 30,
        roles: ["user", "admin"]
      }
    )

    assert_equal "approve", result[:decision]
  end

  private

  def create_rule_with_content(rule_id, content)
    rule = Rule.find_or_create_by(rule_id: rule_id) do |r|
      r.ruleset = content[:ruleset] || "test"
      r.description = "Test rule for #{rule_id}"
      r.status = "active"
    end

    @service.save_rule_version(
      rule_id: rule_id,
      content: content,
      created_by: "test_system",
      changelog: "Test version"
    )
    
    rule.rule_versions.last.activate!
    rule
  end
end

