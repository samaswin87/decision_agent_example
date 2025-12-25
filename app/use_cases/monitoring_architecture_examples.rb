# frozen_string_literal: true

# This file demonstrates all monitoring patterns from MONITORING_ARCHITECTURE.md
# It covers all integration patterns, data flows, and component interactions

require 'decision_agent'
require 'decision_agent/monitoring/metrics_collector'
require 'decision_agent/monitoring/prometheus_exporter'
require 'decision_agent/monitoring/alert_manager'
require 'decision_agent/monitoring/monitored_agent'

module MonitoringArchitectureExamples
  # Custom evaluator for loan approval decisions
  class LoanApprovalEvaluator < DecisionAgent::Evaluators::Base
    def evaluate(context, feedback: {})
      credit_score = context[:credit_score]
      income = context[:annual_income]

      if credit_score >= 700 && income >= 50000
        DecisionAgent::Evaluation.new(
          decision: "approved",
          weight: 0.95,
          reason: "Excellent credit and income",
          evaluator_name: "loan_approval"
        )
      elsif credit_score >= 600 && income >= 30000
        DecisionAgent::Evaluation.new(
          decision: "manual_review",
          weight: 0.60,
          reason: "Borderline case",
          evaluator_name: "loan_approval"
        )
      else
        DecisionAgent::Evaluation.new(
          decision: "rejected",
          weight: 0.90,
          reason: "Insufficient credit or income",
          evaluator_name: "loan_approval"
        )
      end
    end
  end

  # Custom evaluator for fraud detection
  class FraudCheckEvaluator < DecisionAgent::Evaluators::Base
    def evaluate(context, feedback: {})
      transaction_amount = context[:amount]
      risk_score = context[:risk_score]

      if risk_score > 80 || transaction_amount > 10000
        DecisionAgent::Evaluation.new(
          decision: "block",
          weight: 0.85,
          reason: "High risk detected",
          evaluator_name: "fraud_check"
        )
      else
        DecisionAgent::Evaluation.new(
          decision: "allow",
          weight: 0.95,
          reason: "Transaction looks safe",
          evaluator_name: "fraud_check"
        )
      end
    end
  end

  # Custom evaluator for content moderation
  class ContentModerationEvaluator < DecisionAgent::Evaluators::Base
    def evaluate(context, feedback: {})
      toxicity_score = context[:toxicity_score] || context[:severity_score] || 0

      if toxicity_score > 0.8
        DecisionAgent::Evaluation.new(
          decision: "remove",
          weight: 0.95,
          reason: "High toxicity",
          evaluator_name: "content_moderation"
        )
      elsif toxicity_score > 0.5
        DecisionAgent::Evaluation.new(
          decision: "review",
          weight: 0.60,
          reason: "Moderate toxicity",
          evaluator_name: "content_moderation"
        )
      else
        DecisionAgent::Evaluation.new(
          decision: "approve",
          weight: 0.98,
          reason: "Safe content",
          evaluator_name: "content_moderation"
        )
      end
    end
  end

  # Generic test evaluator
  class TestEvaluator < DecisionAgent::Evaluators::Base
    def evaluate(context, feedback: {})
      # Simulate slow operations and errors
      sleep(0.1) if context[:simulate_slow]
      raise "Simulated error" if context[:simulate_error]

      value = context[:value]
      confidence = context[:confidence]

      if value
        if value > 70
          DecisionAgent::Evaluation.new(
            decision: "high",
            weight: 0.90,
            reason: "High value detected",
            evaluator_name: "test_evaluator"
          )
        elsif value > 30
          DecisionAgent::Evaluation.new(
            decision: "medium",
            weight: 0.60,
            reason: "Medium value",
            evaluator_name: "test_evaluator"
          )
        else
          DecisionAgent::Evaluation.new(
            decision: "low",
            weight: 0.40,
            reason: "Low value",
            evaluator_name: "test_evaluator"
          )
        end
      else
        DecisionAgent::Evaluation.new(
          decision: "test",
          weight: confidence || 0.9,
          reason: "Test decision",
          evaluator_name: "test_evaluator"
        )
      end
    end
  end

  # Pricing engine evaluator
  class PricingEngineEvaluator < DecisionAgent::Evaluators::Base
    def evaluate(context, feedback: {})
      tier = context[:tier]

      # If no tier provided, generate random pricing (for test scenarios)
      if tier.nil?
        return DecisionAgent::Evaluation.new(
          decision: "price_#{rand(10..100)}",
          weight: rand(0.7..0.99),
          reason: "Dynamic pricing",
          evaluator_name: "pricing_engine"
        )
      end

      case tier
      when "premium"
        DecisionAgent::Evaluation.new(
          decision: "premium_pricing",
          weight: 0.95,
          reason: "Premium tier customer",
          evaluator_name: "pricing_engine"
        )
      when "standard"
        DecisionAgent::Evaluation.new(
          decision: "standard_pricing",
          weight: 0.80,
          reason: "Standard tier customer",
          evaluator_name: "pricing_engine"
        )
      else
        DecisionAgent::Evaluation.new(
          decision: "basic_pricing",
          weight: 0.70,
          reason: "Basic tier customer",
          evaluator_name: "pricing_engine"
        )
      end
    end
  end

  # Recommendation engine evaluator
  class RecommendationEvaluator < DecisionAgent::Evaluators::Base
    def evaluate(context, feedback: {})
      score = context[:relevance_score]

      # If no relevance score, generate random recommendation (for test scenarios)
      if score.nil?
        return DecisionAgent::Evaluation.new(
          decision: "recommend_#{['A', 'B', 'C'].sample}",
          weight: rand(0.6..0.99),
          reason: "Random recommendation",
          evaluator_name: "recommendation"
        )
      end

      if score > 0.7
        DecisionAgent::Evaluation.new(
          decision: "recommend",
          weight: 0.90,
          reason: "High relevance score",
          evaluator_name: "recommendation"
        )
      else
        DecisionAgent::Evaluation.new(
          decision: "skip",
          weight: 0.60,
          reason: "Low relevance score",
          evaluator_name: "recommendation"
        )
      end
    end
  end
  # ============================================================================
  # PATTERN 1: Automatic Monitoring (Wrapper Pattern)
  # From Architecture: "Pattern 1: Automatic (Wrapper)"
  # ============================================================================

  class AutomaticMonitoringExample
    def self.run
      puts "\n" + "="*80
      puts "PATTERN 1: AUTOMATIC MONITORING (WRAPPER)"
      puts "="*80

      # Create the metrics collector (core component)
      collector = DecisionAgent::Monitoring::MetricsCollector.new(window_size: 3600)

      # Create a simple evaluator for loan decisions
      loan_evaluator = LoanApprovalEvaluator.new

      # Create the agent
      agent = DecisionAgent::Agent.new(evaluators: [loan_evaluator])

      # Wrap with MonitoredAgent - automatic metrics recording
      monitored_agent = DecisionAgent::Monitoring::MonitoredAgent.new(
        agent: agent,
        metrics_collector: collector
      )

      # Make decisions - metrics recorded automatically!
      test_cases = [
        { name: "John Doe", credit_score: 750, annual_income: 80000 },
        { name: "Jane Smith", credit_score: 620, annual_income: 45000 },
        { name: "Bob Johnson", credit_score: 550, annual_income: 25000 }
      ]

      test_cases.each do |context|
        result = monitored_agent.decide(context: context)
        puts "\nDecision for #{context[:name]}:"
        puts "  Decision: #{result.decision}"
        puts "  Confidence: #{result.confidence}"
      end

      # View statistics (automatically computed)
      stats = collector.statistics
      puts "\n--- Statistics ---"
      puts "Total Decisions: #{stats.dig(:decisions, :total)}"
      puts "Avg Duration: #{stats.dig(:performance, :avg_duration_ms)&.round(2)}ms"
      puts "P95 Duration: #{stats.dig(:performance, :p95_duration_ms)&.round(2)}ms"
      puts "Error Count: #{stats.dig(:errors, :total)}"

      collector
    end
  end

  # ============================================================================
  # PATTERN 2: Manual Monitoring (Explicit Recording)
  # From Architecture: "Pattern 2: Manual (Explicit)"
  # ============================================================================

  class ManualMonitoringExample
    def self.run
      puts "\n" + "="*80
      puts "PATTERN 2: MANUAL MONITORING (EXPLICIT RECORDING)"
      puts "="*80

      collector = DecisionAgent::Monitoring::MetricsCollector.new

      # Create agent WITHOUT wrapper
      evaluator = FraudCheckEvaluator.new

      agent = DecisionAgent::Agent.new(evaluators: [evaluator])

      # Manual recording with custom logic
      transactions = [
        { id: "T1", amount: 100, risk_score: 20 },
        { id: "T2", amount: 15000, risk_score: 90 },
        { id: "T3", amount: 500, risk_score: 45 }
      ]

      transactions.each do |context|
        start_time = Time.now

        begin
          result = agent.decide(context: context)
          duration_ms = ((Time.now - start_time) * 1000).round(2)

          # Manual metric recording
          collector.record_decision(
            result,
            context,
            duration_ms: duration_ms
          )

          # Record each evaluation manually
          result.evaluations.each do |eval|
            collector.record_evaluation(eval)
          end

          # Record custom performance metrics
          collector.record_performance(
            operation: "fraud_check",
            duration_ms: duration_ms,
            metadata: {
              transaction_id: context[:id],
              custom_tag: "fraud_detection",
              amount: context[:amount],
              risk_score: context[:risk_score]
            }
          )

          puts "\nTransaction #{context[:id]}: #{result.decision}"

        rescue StandardError => e
          # Manual error recording
          collector.record_error(
            e,
            context: context.merge(
              transaction_id: context[:id],
              error_type: e.class.name
            )
          )
          puts "\nTransaction #{context[:id]}: ERROR - #{e.message}"
        end
      end

      stats = collector.statistics
      puts "\n--- Statistics ---"
      puts "Total Decisions: #{stats.dig(:decisions, :total)}"
      puts "Blocked: #{stats.dig(:decisions, :by_decision, 'block') || 0}"
      puts "Allowed: #{stats.dig(:decisions, :by_decision, 'allow') || 0}"

      collector
    end
  end

  # ============================================================================
  # PATTERN 3: Observer Pattern (Callbacks)
  # From Architecture: "Pattern 3: Observer (Callback)"
  # ============================================================================

  class ObserverPatternExample
    def self.run
      puts "\n" + "="*80
      puts "PATTERN 3: OBSERVER PATTERN (CALLBACKS)"
      puts "="*80

      collector = DecisionAgent::Monitoring::MetricsCollector.new

      # Add observer to track all events in real-time
      collector.add_observer do |event_type, metric|
        case event_type
        when :decision
          puts "\n[OBSERVER] Decision made: #{metric[:final_decision]} (confidence: #{metric[:confidence]})"

          # Simulate sending to analytics service
          if metric[:confidence] < 0.7
            puts "  → Alert: Low confidence decision detected!"
          end

        when :evaluation
          puts "\n[OBSERVER] Evaluation: #{metric[:evaluator_name]} → #{metric[:decision]}"

        when :error
          puts "\n[OBSERVER] ERROR: #{metric[:error_class]} - #{metric[:error_message]}"
          # Simulate Bugsnag/Sentry notification
          puts "  → Sent to error tracking service"

        when :performance
          if metric[:duration_ms] > 1000
            puts "\n[OBSERVER] SLOW OPERATION: #{metric[:operation]} took #{metric[:duration_ms]}ms"
          end
        end
      end

      # Add second observer for custom business logic
      collector.add_observer do |event_type, metric|
        if event_type == :decision
          # Simulate audit logging
          File.open("/tmp/decision_audit.log", "a") do |f|
            f.puts "#{Time.now} | Decision: #{metric[:final_decision]} | Confidence: #{metric[:confidence]}"
          end
        end
      end

      # Create and run decisions
      evaluator = ContentModerationEvaluator.new

      agent = DecisionAgent::Agent.new(evaluators: [evaluator])
      monitored_agent = DecisionAgent::Monitoring::MonitoredAgent.new(
        agent: agent,
        metrics_collector: collector
      )

      # Simulate content moderation decisions
      content_items = [
        { id: "C1", text: "Hello world", toxicity_score: 0.1 },
        { id: "C2", text: "Borderline content", toxicity_score: 0.6 },
        { id: "C3", text: "Toxic content", toxicity_score: 0.9 }
      ]

      content_items.each do |context|
        monitored_agent.decide(context: context)
      end

      puts "\n[OBSERVER] Audit log written to /tmp/decision_audit.log"

      collector
    end
  end

  # ============================================================================
  # ALERT MANAGER: Rule-Based Alerting
  # From Architecture: "Alert Processing Flow"
  # ============================================================================

  class AlertManagerExample
    def self.run
      puts "\n" + "="*80
      puts "ALERT MANAGER: RULE-BASED ALERTING"
      puts "="*80

      collector = DecisionAgent::Monitoring::MetricsCollector.new
      alert_manager = DecisionAgent::Monitoring::AlertManager.new(
        metrics_collector: collector
      )

      # Define alert rules

      # Rule 1: High error rate
      alert_manager.add_rule(
        name: "high_error_rate",
        condition: ->(stats) {
          total = stats.dig(:decisions, :total) || 0
          errors = stats.dig(:errors, :total) || 0
          total > 0 && (errors.to_f / total) > 0.1 # 10% error rate
        },
        severity: :critical,
        message: "Error rate exceeds 10%!",
        cooldown: 60 # Don't spam - wait 60s between alerts
      )

      # Rule 2: Low confidence decisions
      alert_manager.add_rule(
        name: "low_confidence_decisions",
        condition: ->(stats) {
          avg_confidence = stats.dig(:decisions, :avg_confidence)
          avg_confidence && avg_confidence < 0.6
        },
        severity: :warning,
        message: "Average confidence below threshold",
        cooldown: 300
      )

      # Rule 3: Slow performance
      alert_manager.add_rule(
        name: "slow_performance",
        condition: ->(stats) {
          p95 = stats.dig(:performance, :p95_duration_ms)
          p95 && p95 > 500 # P95 exceeds 500ms
        },
        severity: :warning,
        message: "P95 latency exceeds 500ms",
        cooldown: 120
      )

      # Add alert handler
      alert_manager.add_handler do |alert|
        puts "\n🚨 ALERT TRIGGERED!"
        puts "  Rule: #{alert[:rule_name]}"
        puts "  Severity: #{alert[:severity]}"
        puts "  Message: #{alert[:message]}"
        puts "  Time: #{alert[:triggered_at]}"
        puts "  Context: #{alert[:context].inspect}"

        # Simulate Slack notification
        if alert[:severity] == :critical
          puts "  → Sending to #alerts-critical Slack channel"
        else
          puts "  → Sending to #alerts-warning Slack channel"
        end
      end

      # Start monitoring
      alert_manager.start_monitoring(interval: 5)

      # Simulate decisions that trigger alerts
      evaluator = TestEvaluator.new

      agent = DecisionAgent::Agent.new(evaluators: [evaluator])
      monitored_agent = DecisionAgent::Monitoring::MonitoredAgent.new(
        agent: agent,
        metrics_collector: collector
      )

      puts "\nSimulating normal decisions..."
      5.times { monitored_agent.decide(context: { confidence: 0.9 }) }

      puts "\nSimulating low confidence decisions (should trigger alert)..."
      10.times { monitored_agent.decide(context: { confidence: 0.5 }) }

      puts "\nSimulating slow operations (should trigger alert)..."
      5.times { monitored_agent.decide(context: { simulate_slow: true }) }

      puts "\nSimulating errors (should trigger alert)..."
      5.times do
        begin
          monitored_agent.decide(context: { simulate_error: true })
        rescue StandardError => e
          collector.record_error(e, context: {})
        end
      end

      # Wait for alerts to be checked
      puts "\nWaiting for alert checks..."
      sleep(6)

      # View active alerts
      alerts = alert_manager.active_alerts
      puts "\n--- Active Alerts ---"
      if alerts.empty?
        puts "No active alerts"
      else
        alerts.each do |alert|
          puts "#{alert[:severity].to_s.upcase}: #{alert[:rule_name]} - #{alert[:status]}"
        end
      end

      # Acknowledge an alert
      if alerts.any?
        first_alert = alerts.first
        alert_manager.acknowledge_alert(first_alert[:id])
        puts "\nAcknowledged alert: #{first_alert[:rule_name]}"
      end

      alert_manager.stop_monitoring

      collector
    end
  end

  # ============================================================================
  # PROMETHEUS EXPORTER: Metrics Export
  # From Architecture: "Prometheus Scrape Flow"
  # ============================================================================

  class PrometheusExporterExample
    def self.run
      puts "\n" + "="*80
      puts "PROMETHEUS EXPORTER: METRICS EXPORT"
      puts "="*80

      collector = DecisionAgent::Monitoring::MetricsCollector.new
      exporter = DecisionAgent::Monitoring::PrometheusExporter.new(
        metrics_collector: collector,
        namespace: "myapp"
      )

      # Generate some metrics
      evaluator = PricingEngineEvaluator.new

      agent = DecisionAgent::Agent.new(evaluators: [evaluator])
      monitored_agent = DecisionAgent::Monitoring::MonitoredAgent.new(
        agent: agent,
        metrics_collector: collector
      )

      puts "\nGenerating metrics..."
      20.times do |i|
        monitored_agent.decide(context: { product_id: "PROD#{i}" })
      end

      # Register custom KPIs
      exporter.register_kpi(
        name: "business_revenue",
        value: 125000.50,
        labels: { currency: "USD", region: "US" },
        help: "Total business revenue"
      )

      exporter.register_kpi(
        name: "active_users",
        value: 1523,
        labels: { platform: "web" },
        help: "Number of active users"
      )

      # Export in Prometheus text format
      puts "\n--- Prometheus Text Format ---"
      prometheus_text = exporter.export
      puts prometheus_text[0..1000] # Show first 1000 chars
      puts "... (#{prometheus_text.length} total characters)"

      # Export in JSON format
      puts "\n--- JSON Format ---"
      json_metrics = exporter.metrics_hash
      puts JSON.pretty_generate(json_metrics.first(5)) # Show first 5 metrics

      # Simulate Prometheus scrape
      puts "\n--- Simulating Prometheus Scrape ---"
      puts "Prometheus would GET /metrics endpoint"
      puts "Frequency: Every 15 seconds"
      puts "Metrics exported: #{json_metrics.keys.count}"

      # Show key metrics
      stats = collector.statistics
      puts "\n--- Key Metrics ---"
      puts "myapp_decisions_total: #{stats.dig(:decisions, :total)}"
      puts "myapp_decisions_avg_confidence: #{stats.dig(:decisions, :avg_confidence)&.round(4)}"
      puts "myapp_performance_avg_duration_ms: #{stats.dig(:performance, :avg_duration_ms)&.round(2)}"
      puts "myapp_performance_p95_duration_ms: #{stats.dig(:performance, :p95_duration_ms)&.round(2)}"
      puts "myapp_performance_p99_duration_ms: #{stats.dig(:performance, :p99_duration_ms)&.round(2)}"

      collector
    end
  end

  # ============================================================================
  # TIME SERIES: Bucketed Metrics Over Time
  # From Architecture: "Data Flow - Time Series"
  # ============================================================================

  class TimeSeriesExample
    def self.run
      puts "\n" + "="*80
      puts "TIME SERIES: BUCKETED METRICS OVER TIME"
      puts "="*80

      collector = DecisionAgent::Monitoring::MetricsCollector.new

      evaluator = RecommendationEvaluator.new

      agent = DecisionAgent::Agent.new(evaluators: [evaluator])
      monitored_agent = DecisionAgent::Monitoring::MonitoredAgent.new(
        agent: agent,
        metrics_collector: collector
      )

      # Generate decisions over time
      puts "\nGenerating time series data..."
      50.times do |i|
        monitored_agent.decide(context: { user_id: "U#{i}" })
        sleep(0.05) # Spread over time
      end

      # Get time series data with different bucket sizes

      # 10-second buckets
      puts "\n--- Time Series (10-second buckets) ---"
      series_10s = collector.time_series(
        metric_type: :decisions,
        bucket_size: 10,
        time_range: 60
      )

      series_10s.each do |bucket|
        puts "#{bucket[:timestamp]}: #{bucket[:count]} decisions, avg confidence: #{bucket[:avg_confidence]&.round(3)}"
      end

      # 5-second buckets
      puts "\n--- Time Series (5-second buckets) ---"
      series_5s = collector.time_series(
        metric_type: :decisions,
        bucket_size: 5,
        time_range: 30
      )

      series_5s.each do |bucket|
        puts "#{bucket[:timestamp]}: #{bucket[:count]} decisions"
      end

      # Performance time series
      puts "\n--- Performance Time Series ---"
      perf_series = collector.time_series(
        metric_type: :performance,
        bucket_size: 10
      )

      perf_series.each do |bucket|
        puts "#{bucket[:timestamp]}: avg #{bucket[:avg_duration_ms]&.round(2)}ms, max #{bucket[:max_duration_ms]&.round(2)}ms"
      end

      collector
    end
  end

  # ============================================================================
  # MEMORY MANAGEMENT: Window Size and Cleanup
  # From Architecture: "Memory Management"
  # ============================================================================

  class MemoryManagementExample
    def self.run
      puts "\n" + "="*80
      puts "MEMORY MANAGEMENT: WINDOW SIZE AND CLEANUP"
      puts "="*80

      # Create collector with 30-second window
      collector = DecisionAgent::Monitoring::MetricsCollector.new(window_size: 30)

      evaluator = TestEvaluator.new

      agent = DecisionAgent::Agent.new(evaluators: [evaluator])
      monitored_agent = DecisionAgent::Monitoring::MonitoredAgent.new(
        agent: agent,
        metrics_collector: collector
      )

      puts "\nWindow size: 30 seconds"
      puts "Metrics older than 30 seconds are automatically deleted"

      # Generate initial metrics
      puts "\nGenerating 20 decisions..."
      20.times { monitored_agent.decide(context: {}) }

      stats = collector.statistics
      puts "Total decisions: #{stats.dig(:decisions, :total)}"

      puts "\nWaiting 35 seconds for metrics to expire..."
      puts "(This demonstrates automatic cleanup)"

      # Simulate passage of time
      35.times do |i|
        print "\rTime elapsed: #{i + 1}s / 35s"
        sleep(1)
      end

      # Make a new decision to trigger cleanup
      puts "\n\nMaking new decision (triggers cleanup)..."
      monitored_agent.decide(context: {})

      stats = collector.statistics
      puts "Total decisions after cleanup: #{stats.dig(:decisions, :total)}"
      puts "(Old metrics automatically removed!)"

      # Test different window sizes
      puts "\n--- Different Window Sizes ---"

      configs = [
        { size: 3600, desc: "1 hour - default for production" },
        { size: 1800, desc: "30 minutes - high traffic systems" },
        { size: 900, desc: "15 minutes - very high traffic" },
        { size: 300, desc: "5 minutes - extreme high traffic" }
      ]

      configs.each do |config|
        puts "\nWindow: #{config[:size]}s (#{config[:desc]})"
        puts "  Approx memory for 10K decisions/hour: #{(config[:size] / 3600.0 * 10000 * 1).round(1)}MB"
      end

      collector
    end
  end

  # ============================================================================
  # FULL DASHBOARD SERVER SIMULATION
  # From Architecture: "Dashboard Server (Sinatra)"
  # ============================================================================

  class DashboardServerExample
    def self.run
      puts "\n" + "="*80
      puts "FULL DASHBOARD SERVER SIMULATION"
      puts "="*80

      # Initialize all components
      collector = DecisionAgent::Monitoring::MetricsCollector.new
      exporter = DecisionAgent::Monitoring::PrometheusExporter.new(
        metrics_collector: collector,
        namespace: "dashboard"
      )
      alert_manager = DecisionAgent::Monitoring::AlertManager.new(
        metrics_collector: collector
      )

      # Add observer for WebSocket simulation
      websocket_clients = []

      collector.add_observer do |event_type, metric|
        # Simulate WebSocket broadcast
        message = {
          type: "metric_update",
          event: event_type,
          data: metric,
          timestamp: Time.now.iso8601
        }

        websocket_clients.each do |client|
          client.call(message)
        end
      end

      # Add alert handler
      alert_manager.add_rule(
        name: "dashboard_health",
        condition: ->(stats) { stats.dig(:errors, :total).to_i > 5 },
        severity: :warning,
        message: "Dashboard health check failed"
      )

      alert_manager.add_handler do |alert|
        puts "\n📊 [DASHBOARD ALERT] #{alert[:rule_name]}: #{alert[:message]}"
      end

      # Simulate WebSocket client
      websocket_clients << ->(message) {
        if message[:event] == :decision
          puts "\n🌐 [WebSocket] Broadcasting decision: #{message[:data][:final_decision]}"
        end
      }

      # Start alert monitoring
      alert_manager.start_monitoring

      # Simulate API endpoints
      puts "\n--- Simulated Dashboard Endpoints ---"
      puts "GET  /                          → HTML dashboard"
      puts "GET  /api/stats                 → Current statistics (JSON)"
      puts "GET  /api/timeseries/:type      → Time series data (JSON)"
      puts "GET  /metrics                   → Prometheus metrics (text)"
      puts "GET  /api/alerts                → Active alerts (JSON)"
      puts "POST /api/kpi                   → Register custom KPI"
      puts "POST /api/alerts/:id/acknowledge → Acknowledge alert"
      puts "WS   /ws                        → WebSocket real-time updates"

      # Create agent and generate traffic
      evaluator = TestEvaluator.new

      agent = DecisionAgent::Agent.new(evaluators: [evaluator])
      monitored_agent = DecisionAgent::Monitoring::MonitoredAgent.new(
        agent: agent,
        metrics_collector: collector
      )

      # Simulate dashboard traffic
      puts "\n--- Simulating Dashboard Traffic ---"

      # 1. Generate decisions
      puts "\n1. Generating decisions..."
      10.times { monitored_agent.decide(context: {}) }

      # 2. GET /api/stats
      puts "\n2. GET /api/stats"
      stats = collector.statistics
      puts JSON.pretty_generate({
        decisions: stats[:decisions]&.slice(:total, :avg_confidence),
        performance: stats[:performance]&.slice(:avg_duration_ms, :p95_duration_ms),
        errors: stats[:errors]&.slice(:total)
      })

      # 3. GET /api/timeseries/decisions
      puts "\n3. GET /api/timeseries/decisions"
      series = collector.time_series(metric_type: :decisions, bucket_size: 10)
      puts "Returned #{series.length} time buckets"

      # 4. GET /metrics (Prometheus)
      puts "\n4. GET /metrics (Prometheus format)"
      prometheus_output = exporter.export
      puts "#{prometheus_output.lines.first(5).join}... (#{prometheus_output.lines.count} lines total)"

      # 5. POST /api/kpi
      puts "\n5. POST /api/kpi (Register custom KPI)"
      exporter.register_kpi(
        name: "dashboard_uptime",
        value: 99.9,
        help: "Dashboard uptime percentage"
      )
      puts "Registered: dashboard_uptime = 99.9%"

      # 6. GET /api/alerts
      puts "\n6. GET /api/alerts"
      alerts = alert_manager.active_alerts
      puts "Active alerts: #{alerts.length}"

      # Wait for potential alerts
      sleep(2)

      alert_manager.stop_monitoring

      puts "\n--- Dashboard Server Simulation Complete ---"
      puts "In production, this would be a Sinatra/Rails server"
      puts "accessible via HTTP and WebSocket connections"

      collector
    end
  end

  # ============================================================================
  # MAIN RUNNER
  # ============================================================================

  def self.run_all_examples
    puts "\n" + "="*80
    puts "DECISION AGENT MONITORING ARCHITECTURE EXAMPLES"
    puts "Based on: wiki/MONITORING_ARCHITECTURE.md"
    puts "="*80

    examples = [
      AutomaticMonitoringExample,
      ManualMonitoringExample,
      ObserverPatternExample,
      AlertManagerExample,
      PrometheusExporterExample,
      TimeSeriesExample,
      MemoryManagementExample,
      DashboardServerExample
    ]

    examples.each do |example_class|
      begin
        example_class.run
        puts "\n✅ #{example_class.name} completed"
      rescue StandardError => e
        puts "\n❌ #{example_class.name} failed: #{e.message}"
        puts e.backtrace.first(3)
      end

      puts "\nPress Enter to continue to next example..."
      gets
    end

    puts "\n" + "="*80
    puts "ALL EXAMPLES COMPLETED"
    puts "="*80
  end
end

# Run if executed directly
if __FILE__ == $0
  MonitoringArchitectureExamples.run_all_examples
end
