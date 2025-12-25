# Monitoring & Observability Use Case
# Demonstrates comprehensive monitoring, metrics tracking, performance analysis, and audit logging
# This showcases decision_agent's monitoring capabilities for production environments
class MonitoringObservabilityUseCase
  RULE_ID = 'monitored_credit_decision'

  # Decision rules with comprehensive monitoring metadata
  def self.rules_definition
    {
      version: "2.0",
      ruleset: "monitored_credit_decisions",
      description: "Credit decisions with full observability and monitoring",
      metadata: {
        sla_target_ms: 200,
        alert_on_latency_ms: 500,
        track_metrics: true,
        audit_level: "detailed"
      },
      rules: [
        {
          id: "high_value_approval",
          if: {
            all: [
              { field: "credit_score", op: "gte", value: 780 },
              { field: "requested_amount", op: "lte", value: 50000 },
              { field: "debt_to_income", op: "lte", value: 0.30 }
            ]
          },
          then: {
            decision: "approved",
            weight: 1.0,
            reason: "High value customer - approved"
          }
        },
        {
          id: "standard_approval",
          if: {
            all: [
              { field: "credit_score", op: "gte", value: 680 },
              { field: "requested_amount", op: "lte", value: 25000 },
              { field: "debt_to_income", op: "lte", value: 0.40 }
            ]
          },
          then: {
            decision: "approved",
            weight: 0.85,
            reason: "Standard approval criteria met"
          }
        },
        {
          id: "risk_review",
          if: {
            any: [
              {
                all: [
                  { field: "credit_score", op: "gte", value: 650 },
                  { field: "credit_score", op: "lt", value: 680 }
                ]
              },
              { field: "debt_to_income", op: "gt", value: 0.40 }
            ]
          },
          then: {
            decision: "review_required",
            weight: 0.6,
            reason: "Requires manual risk assessment"
          }
        },
        {
          id: "high_risk_decline",
          if: {
            any: [
              { field: "credit_score", op: "lt", value: 650 },
              { field: "debt_to_income", op: "gt", value: 0.50 },
              { field: "recent_bankruptcies", op: "gt", value: 0 }
            ]
          },
          then: {
            decision: "declined",
            weight: 1.0,
            reason: "High risk - application declined"
          }
        }
      ]
    }
  end

  # Enhanced evaluation with comprehensive monitoring
  def self.evaluate_with_monitoring(context, request_id: nil)
    request_id ||= SecureRandom.uuid
    start_time = Time.current

    # Pre-evaluation metrics
    metrics = {
      request_id: request_id,
      started_at: start_time,
      context_size_bytes: context.to_json.bytesize,
      rule_id: RULE_ID
    }

    begin
      setup_rules

      # Perform evaluation
      service = DecisionService.instance
      eval_start = Time.current

      result = service.evaluate(
        rule_id: RULE_ID,
        context: context
      )

      eval_duration = ((Time.current - eval_start) * 1000).round(3)

      # Post-evaluation metrics
      metrics.merge!(
        evaluation_duration_ms: eval_duration,
        decision: result[:decision],
        confidence: result[:confidence],
        rules_matched: result[:evaluations]&.size || 0,
        status: 'success'
      )

      # Check SLA breach
      sla_target_ms = rules_definition.dig(:metadata, :sla_target_ms) || 200
      metrics[:sla_breached] = eval_duration > sla_target_ms

      # Log metrics
      log_metrics(metrics)

      # Check if alerts needed
      check_and_trigger_alerts(metrics, result)

      # Format comprehensive result
      format_monitored_result(result, metrics, context)

    rescue StandardError => e
      # Error tracking
      error_metrics = metrics.merge(
        status: 'error',
        error_type: e.class.name,
        error_message: e.message,
        duration_ms: ((Time.current - start_time) * 1000).round(3)
      )

      log_error(error_metrics, e)

      {
        request_id: request_id,
        status: 'error',
        error: e.message,
        metrics: error_metrics
      }
    end
  end

  # Performance benchmarking with detailed metrics
  def self.run_performance_benchmark(iterations: 1000, warmup: 100)
    results = {
      benchmark_id: SecureRandom.uuid,
      started_at: Time.current,
      configuration: {
        iterations: iterations,
        warmup: warmup,
        rule_id: RULE_ID
      },
      warmup_phase: {},
      test_phase: {},
      detailed_metrics: []
    }

    setup_rules

    # Warmup phase
    warmup_latencies = []
    warmup.times do
      context = generate_random_context
      start = Time.current
      evaluate_with_monitoring(context)
      warmup_latencies << ((Time.current - start) * 1000).round(3)
    end

    results[:warmup_phase] = {
      iterations: warmup,
      avg_latency_ms: (warmup_latencies.sum / warmup).round(3),
      min_latency_ms: warmup_latencies.min,
      max_latency_ms: warmup_latencies.max
    }

    # Clear cache for fair test
    DecisionService.instance.clear_cache

    # Test phase with detailed tracking
    latencies = []
    memory_samples = []
    cpu_samples = []

    iterations.times do |i|
      context = generate_random_context
      gc_start = GC.stat(:total_allocated_objects)

      start = Time.current
      result = evaluate_with_monitoring(context)
      latency = ((Time.current - start) * 1000).round(3)

      gc_objects = GC.stat(:total_allocated_objects) - gc_start

      latencies << latency

      # Sample memory every 100 iterations
      if i % 100 == 0
        memory_samples << {
          iteration: i,
          memory_mb: (GC.stat(:heap_allocated_pages) * GC::INTERNAL_CONSTANTS[:HEAP_PAGE_OBJ_LIMIT] * 40 / 1024.0 / 1024.0).round(2)
        }
      end

      # Track outliers (p99+)
      if latency > 100
        results[:detailed_metrics] << {
          iteration: i,
          latency_ms: latency,
          decision: result[:decision],
          gc_objects: gc_objects
        }
      end
    end

    sorted_latencies = latencies.sort

    results[:test_phase] = {
      iterations: iterations,
      duration_seconds: (Time.current - results[:started_at]).round(3),
      throughput_per_second: (iterations / (Time.current - results[:started_at])).round(2),
      latency_stats: {
        min_ms: sorted_latencies.first.round(3),
        max_ms: sorted_latencies.last.round(3),
        mean_ms: (latencies.sum / iterations).round(3),
        median_ms: sorted_latencies[iterations / 2].round(3),
        p95_ms: sorted_latencies[(iterations * 0.95).to_i].round(3),
        p99_ms: sorted_latencies[(iterations * 0.99).to_i].round(3),
        p999_ms: sorted_latencies[(iterations * 0.999).to_i].round(3),
        std_dev: calculate_std_dev(latencies).round(3)
      },
      memory_analysis: {
        samples: memory_samples,
        trend: memory_samples.size > 1 ? (memory_samples.last[:memory_mb] - memory_samples.first[:memory_mb]).round(2) : 0
      }
    }

    results[:completed_at] = Time.current
    results[:total_duration_seconds] = (results[:completed_at] - results[:started_at]).round(3)

    results
  end

  # Concurrent load testing with monitoring
  def self.run_load_test(duration_seconds: 30, concurrent_threads: 10)
    test_id = SecureRandom.uuid
    start_time = Time.current
    end_time = start_time + duration_seconds

    results = {
      test_id: test_id,
      config: {
        duration_seconds: duration_seconds,
        concurrent_threads: concurrent_threads,
        started_at: start_time
      },
      thread_metrics: [],
      aggregate_metrics: {},
      errors: []
    }

    setup_rules

    # Run concurrent threads
    threads = []
    concurrent_threads.times do |thread_id|
      threads << Thread.new do
        thread_results = {
          thread_id: thread_id,
          requests: 0,
          errors: 0,
          latencies: [],
          decisions: Hash.new(0)
        }

        while Time.current < end_time
          begin
            context = generate_random_context
            start = Time.current

            result = evaluate_with_monitoring(context, request_id: "#{test_id}_#{thread_id}_#{thread_results[:requests]}")

            latency = ((Time.current - start) * 1000).round(3)

            thread_results[:requests] += 1
            thread_results[:latencies] << latency
            thread_results[:decisions][result[:decision]] += 1

          rescue StandardError => e
            thread_results[:errors] += 1
            results[:errors] << {
              thread_id: thread_id,
              error: e.message,
              timestamp: Time.current
            }
          end
        end

        thread_results
      end
    end

    # Collect results
    results[:thread_metrics] = threads.map(&:value)

    # Calculate aggregates
    total_requests = results[:thread_metrics].sum { |t| t[:requests] }
    total_errors = results[:thread_metrics].sum { |t| t[:errors] }
    all_latencies = results[:thread_metrics].flat_map { |t| t[:latencies] }.sort
    actual_duration = (Time.current - start_time).to_f

    results[:aggregate_metrics] = {
      total_requests: total_requests,
      total_errors: total_errors,
      error_rate: total_requests > 0 ? (total_errors.to_f / total_requests * 100).round(3) : 0,
      throughput_per_second: (total_requests / actual_duration).round(2),
      actual_duration_seconds: actual_duration.round(3),
      latency_percentiles: {
        p50: percentile(all_latencies, 50),
        p75: percentile(all_latencies, 75),
        p90: percentile(all_latencies, 90),
        p95: percentile(all_latencies, 95),
        p99: percentile(all_latencies, 99)
      },
      decisions_breakdown: results[:thread_metrics].reduce(Hash.new(0)) { |acc, t|
        t[:decisions].each { |k, v| acc[k] += v }
        acc
      }
    }

    results[:completed_at] = Time.current
    results
  end

  # Real-time metrics streaming (simulated)
  def self.stream_metrics(duration_seconds: 60, interval_seconds: 1)
    metrics_stream = []
    start_time = Time.current

    (duration_seconds / interval_seconds).times do |interval|
      interval_start = Time.current
      requests = 0
      latencies = []

      # Simulate requests during interval
      while Time.current - interval_start < interval_seconds
        context = generate_random_context
        start = Time.current
        evaluate_with_monitoring(context)
        latencies << ((Time.current - start) * 1000).round(3)
        requests += 1
      end

      # Emit interval metrics
      interval_metrics = {
        timestamp: Time.current,
        interval: interval,
        requests_per_second: requests / interval_seconds,
        avg_latency_ms: latencies.any? ? (latencies.sum / latencies.size).round(3) : 0,
        max_latency_ms: latencies.max || 0,
        requests: requests
      }

      metrics_stream << interval_metrics

      # In real implementation, this would emit to monitoring system
      Rails.logger.info("Metrics: #{interval_metrics.to_json}")
    end

    {
      test_duration_seconds: duration_seconds,
      interval_seconds: interval_seconds,
      metrics: metrics_stream,
      summary: {
        total_requests: metrics_stream.sum { |m| m[:requests] },
        avg_throughput: (metrics_stream.sum { |m| m[:requests_per_second] } / metrics_stream.size).round(2),
        avg_latency_ms: (metrics_stream.sum { |m| m[:avg_latency_ms] } / metrics_stream.size).round(3)
      }
    }
  end

  def self.setup_rules
    service = DecisionService.instance

    rule = Rule.find_or_initialize_by(rule_id: RULE_ID)
    rule.ruleset = 'monitored_credit_decisions'
    rule.description = 'Credit decisions with full observability'
    rule.status = 'active'
    rule.save!

    unless rule.active_version
      version = service.save_rule_version(
        rule_id: RULE_ID,
        content: rules_definition,
        created_by: 'system',
        changelog: 'Initial version with monitoring metadata'
      )
      version.activate!
    end
  end

  private

  def self.generate_random_context
    {
      application_id: SecureRandom.uuid,
      credit_score: rand(550..850),
      requested_amount: rand(5000..100000),
      debt_to_income: rand(0.15..0.60).round(2),
      recent_bankruptcies: [0, 0, 0, 0, 1].sample,
      employment_years: rand(0..20)
    }
  end

  def self.format_monitored_result(result, metrics, context)
    {
      # Decision result
      request_id: metrics[:request_id],
      decision: result[:decision],
      confidence: result[:confidence],
      explanations: result[:explanations],

      # Performance metrics
      performance: {
        evaluation_time_ms: metrics[:evaluation_duration_ms],
        sla_target_ms: rules_definition.dig(:metadata, :sla_target_ms),
        sla_breached: metrics[:sla_breached],
        context_size_bytes: metrics[:context_size_bytes]
      },

      # Monitoring metadata
      monitoring: {
        rules_evaluated: metrics[:rules_matched],
        timestamp: metrics[:started_at],
        category: result.dig(:evaluations, 0, :outcome, :monitoring, :category),
        business_impact: result.dig(:evaluations, 0, :outcome, :monitoring, :business_impact)
      },

      # Audit trail
      audit: {
        request_id: metrics[:request_id],
        rule_id: RULE_ID,
        rule_version: result[:audit_payload]&.dig(:rule_version),
        context_hash: Digest::SHA256.hexdigest(context.to_json)[0..16],
        evaluated_at: metrics[:started_at].iso8601
      }
    }
  end

  def self.log_metrics(metrics)
    # In production, send to monitoring system (Datadog, New Relic, etc.)
    Rails.logger.info("[METRICS] #{metrics.to_json}")
  end

  def self.log_error(metrics, exception)
    # In production, send to error tracking (Sentry, Rollbar, etc.)
    Rails.logger.error("[ERROR] #{metrics.to_json}")
    Rails.logger.error(exception.backtrace.join("\n"))
  end

  def self.check_and_trigger_alerts(metrics, result)
    alerts = []

    # SLA breach alert
    if metrics[:sla_breached]
      alerts << {
        type: 'sla_breach',
        severity: 'warning',
        message: "Evaluation exceeded SLA: #{metrics[:evaluation_duration_ms]}ms",
        threshold: rules_definition.dig(:metadata, :sla_target_ms)
      }
    end

    # High latency alert
    alert_threshold = rules_definition.dig(:metadata, :alert_on_latency_ms) || 500
    if metrics[:evaluation_duration_ms] > alert_threshold
      alerts << {
        type: 'high_latency',
        severity: 'critical',
        message: "High latency detected: #{metrics[:evaluation_duration_ms]}ms",
        threshold: alert_threshold
      }
    end

    # Log alerts (in production, send to alerting system)
    alerts.each do |alert|
      Rails.logger.warn("[ALERT] #{alert.to_json}")
    end

    alerts
  end

  def self.calculate_std_dev(values)
    mean = values.sum / values.size.to_f
    variance = values.map { |v| (v - mean) ** 2 }.sum / values.size
    Math.sqrt(variance)
  end

  def self.percentile(sorted_array, percentile)
    return 0 if sorted_array.empty?
    k = (percentile / 100.0) * (sorted_array.length - 1)
    f = k.floor
    c = k.ceil

    if f == c
      sorted_array[k].round(3)
    else
      (sorted_array[f] * (c - k) + sorted_array[c] * (k - f)).round(3)
    end
  end
end
