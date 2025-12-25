# frozen_string_literal: true

# Simplified Monitoring Examples based on MONITORING_ARCHITECTURE.md
# These examples demonstrate the monitoring patterns using the correct API

require 'decision_agent'
require 'decision_agent/monitoring/metrics_collector'
require 'decision_agent/monitoring/prometheus_exporter'
require 'decision_agent/monitoring/alert_manager'
require 'decision_agent/monitoring/monitored_agent'

module MonitoringSimpleExamples
  # Example 1: Automatic Monitoring with Wrapper Pattern
  class AutomaticMonitoring
    def self.run
      puts "\n" + "="*80
      puts "EXAMPLE 1: AUTOMATIC MONITORING (WRAPPER PATTERN)"
      puts "="*80

      # Create metrics collector
      collector = DecisionAgent::Monitoring::MetricsCollector.new(window_size: 3600)

      # Create evaluator using JSON rules
      rules = {
        version: "1.0",
        ruleset: "loan_approval",
        rules: [
          {
            id: "approve_good_credit",
            if: { field: "credit_score", op: "gte", value: 700 },
            then: { decision: "approved", weight: 0.95, reason: "Excellent credit" }
          },
          {
            id: "manual_review_lower",
            if: { field: "credit_score", op: "gte", value: 600 },
            then: { decision: "manual_review", weight: 0.60, reason: "Borderline" }
          },
          {
            id: "manual_review_upper",
            if: { field: "credit_score", op: "lt", value: 700 },
            then: { decision: "manual_review", weight: 0.60, reason: "Borderline" }
          },
          {
            id: "reject_poor_credit",
            if: { field: "credit_score", op: "lt", value: 600 },
            then: { decision: "rejected", weight: 0.90, reason: "Insufficient credit" }
          }
        ]
      }

      evaluator = DecisionAgent::Evaluators::JsonRuleEvaluator.new(rules_json: rules)
      agent = DecisionAgent::Agent.new(evaluators: [evaluator])

      # Wrap with MonitoredAgent - automatic metrics!
      monitored_agent = DecisionAgent::Monitoring::MonitoredAgent.new(
        agent: agent,
        metrics_collector: collector
      )

      # Make decisions
      test_cases = [
        { name: "John Doe", credit_score: 750 },
        { name: "Jane Smith", credit_score: 620 },
        { name: "Bob Johnson", credit_score: 550 }
      ]

      puts "\nMaking decisions (metrics recorded automatically)...\n"
      test_cases.each do |data|
        context = DecisionAgent::Context.new(data)
        decision = monitored_agent.decide(context: context)
        puts "  #{data[:name]}: #{decision.decision} (confidence: #{decision.confidence.round(2)})"
      end

      # View statistics
      stats = collector.statistics
      puts "\n--- Statistics ---"
      puts "Total Decisions: #{stats.dig(:decisions, :total)}"
      puts "Avg Confidence: #{stats.dig(:decisions, :avg_confidence)&.round(3)}"
      puts "Avg Duration: #{stats.dig(:performance, :avg_duration_ms)&.round(2)}ms"

      collector
    end
  end

  # Example 2: Manual Monitoring with Custom Metadata
  class ManualMonitoring
    def self.run
      puts "\n" + "="*80
      puts "EXAMPLE 2: MANUAL MONITORING (EXPLICIT RECORDING)"
      puts "="*80

      collector = DecisionAgent::Monitoring::MetricsCollector.new

      rules = {
        version: "1.0",
        ruleset: "fraud_detection",
        rules: [
          {
            id: "block_high_risk",
            if: { field: "risk_score", op: "gt", value: 80 },
            then: { decision: "block", weight: 0.95, reason: "High risk" }
          },
          {
            id: "allow_low_risk",
            if: { field: "risk_score", op: "lte", value: 80 },
            then: { decision: "allow", weight: 0.90, reason: "Safe" }
          }
        ]
      }

      evaluator = DecisionAgent::Evaluators::JsonRuleEvaluator.new(rules_json: rules)
      agent = DecisionAgent::Agent.new(evaluators: [evaluator])

      transactions = [
        { id: "T1", amount: 100, risk_score: 20 },
        { id: "T2", amount: 15000, risk_score: 90 },
        { id: "T3", amount: 500, risk_score: 45 }
      ]

      puts "\nProcessing transactions with manual metric recording...\n"
      transactions.each do |data|
        context = DecisionAgent::Context.new(data)
        start = Time.now
        decision = agent.decide(context: context)
        duration_ms = ((Time.now - start) * 1000).round(2)

        # Manual recording with custom metadata
        collector.record_decision(
          decision.decision,
          decision.confidence,
          duration_ms: duration_ms,
          metadata: {
            transaction_id: data[:id],
            amount: data[:amount],
            environment: "production"
          }
        )

        puts "  #{data[:id]}: #{decision.decision} (#{duration_ms}ms)"
      end

      stats = collector.statistics
      puts "\n--- Statistics ---"
      puts "Total: #{stats.dig(:decisions, :total)}"
      puts "By Decision: #{stats.dig(:decisions, :by_decision)}"

      collector
    end
  end

  # Example 3: Observer Pattern for Real-time Events
  class ObserverPattern
    def self.run
      puts "\n" + "="*80
      puts "EXAMPLE 3: OBSERVER PATTERN (REAL-TIME CALLBACKS)"
      puts "="*80

      collector = DecisionAgent::Monitoring::MetricsCollector.new

      # Add observer for real-time notifications
      puts "\nAdding observers...\n"
      collector.add_observer do |event_type, metric|
        case event_type
        when :decision
          confidence = metric[:confidence]
          if confidence < 0.7
            puts "  [ALERT] Low confidence decision: #{metric[:decision]} (#{confidence.round(2)})"
          end
        when :error
          puts "  [ERROR] #{metric[:error_class]}: #{metric[:error_message]}"
        end
      end

      rules = {
        version: "1.0",
        ruleset: "content_moderation",
        rules: [
          {
            id: "remove_toxic",
            if: { field: "toxicity", op: "gt", value: 0.8 },
            then: { decision: "remove", weight: 0.95, reason: "Toxic content" }
          },
          {
            id: "review_moderate",
            if: { field: "toxicity", op: "gt", value: 0.5 },
            then: { decision: "review", weight: 0.60, reason: "Moderate toxicity" }
          },
          {
            id: "approve_safe",
            if: { field: "toxicity", op: "lte", value: 0.5 },
            then: { decision: "approve", weight: 0.98, reason: "Safe" }
          }
        ]
      }

      evaluator = DecisionAgent::Evaluators::JsonRuleEvaluator.new(rules_json: rules)
      agent = DecisionAgent::Agent.new(evaluators: [evaluator])
      monitored_agent = DecisionAgent::Monitoring::MonitoredAgent.new(
        agent: agent,
        metrics_collector: collector
      )

      content = [
        { id: "C1", toxicity: 0.1 },
        { id: "C2", toxicity: 0.6 },
        { id: "C3", toxicity: 0.9 }
      ]

      puts "Processing content (observers will react)...\n"
      content.each do |data|
        context = DecisionAgent::Context.new(data)
        decision = monitored_agent.decide(context: context)
        puts "  #{data[:id]}: #{decision.decision}"
      end

      collector
    end
  end

  # Example 4: Alert Manager with Rules
  class AlertManagerDemo
    def self.run
      puts "\n" + "="*80
      puts "EXAMPLE 4: ALERT MANAGER (RULE-BASED ALERTING)"
      puts "="*80

      collector = DecisionAgent::Monitoring::MetricsCollector.new
      alert_manager = DecisionAgent::Monitoring::AlertManager.new(
        metrics_collector: collector,
        check_interval: 5
      )

      # Add alert rules using built-in helpers
      puts "\nConfiguring alert rules...\n"

      alert_manager.add_rule(
        name: "High Error Rate",
        condition: DecisionAgent::Monitoring::AlertManager.high_error_rate(threshold: 0.1),
        severity: :critical,
        message: "Error rate exceeds 10%",
        cooldown: 60
      )

      alert_manager.add_rule(
        name: "Low Confidence",
        condition: DecisionAgent::Monitoring::AlertManager.low_confidence(threshold: 0.6),
        severity: :warning,
        message: "Avg confidence below 60%",
        cooldown: 60
      )

      # Add alert handler
      alert_manager.add_handler do |alert|
        puts "\n  [ALERT TRIGGERED]"
        puts "   Rule: #{alert[:rule_name]}"
        puts "   Severity: #{alert[:severity]}"
        puts "   Message: #{alert[:message]}"
      end

      alert_manager.start

      # Create agent
      rules = {
        version: "1.0",
        ruleset: "test",
        rules: [
          {
            id: "test_rule",
            if: { field: "value", op: "gte", value: 0 },
            then: { decision: "test", weight: 0.5, reason: "Test" }
          }
        ]
      }

      evaluator = DecisionAgent::Evaluators::JsonRuleEvaluator.new(rules_json: rules)
      agent = DecisionAgent::Agent.new(evaluators: [evaluator])
      monitored_agent = DecisionAgent::Monitoring::MonitoredAgent.new(
        agent: agent,
        metrics_collector: collector
      )

      puts "Generating low confidence decisions to trigger alert...\n"
      10.times do
        context = DecisionAgent::Context.new({ value: 1 })
        monitored_agent.decide(context: context)
      end

      puts "\nWaiting for alert checks (6 seconds)..."
      sleep(6)

      alert_manager.stop
      puts "\nAlert manager stopped."

      collector
    end
  end

  # Example 5: Prometheus Exporter
  class PrometheusExport
    def self.run
      puts "\n" + "="*80
      puts "EXAMPLE 5: PROMETHEUS EXPORTER"
      puts "="*80

      collector = DecisionAgent::Monitoring::MetricsCollector.new
      exporter = DecisionAgent::Monitoring::PrometheusExporter.new(
        metrics_collector: collector,
        namespace: "myapp"
      )

      # Generate some metrics
      rules = {
        version: "1.0",
        ruleset: "pricing",
        rules: [
          {
            id: "price_rule",
            if: { field: "tier", op: "eq", value: "premium" },
            then: { decision: "price_100", weight: 0.9, reason: "Premium" }
          },
          {
            id: "default_price",
            if: { field: "tier", op: "ne", value: "premium" },
            then: { decision: "price_50", weight: 0.8, reason: "Standard" }
          }
        ]
      }

      evaluator = DecisionAgent::Evaluators::JsonRuleEvaluator.new(rules_json: rules)
      agent = DecisionAgent::Agent.new(evaluators: [evaluator])
      monitored_agent = DecisionAgent::Monitoring::MonitoredAgent.new(
        agent: agent,
        metrics_collector: collector
      )

      puts "\nGenerating metrics..."
      20.times do |i|
        tier = i.even? ? "premium" : "standard"
        context = DecisionAgent::Context.new({ tier: tier })
        monitored_agent.decide(context: context)
      end

      # Register custom KPI
      exporter.register_kpi(
        name: "business_revenue",
        type: :gauge,
        value: 125000.50,
        labels: { currency: "USD" },
        help: "Total revenue"
      )

      # Export in Prometheus format
      puts "\n--- Prometheus Text Format (first 800 chars) ---"
      prometheus_text = exporter.export
      puts prometheus_text[0..800]
      puts "\n... (#{prometheus_text.length} total characters)"

      # Show key metrics
      stats = collector.statistics
      puts "\n--- Key Metrics ---"
      puts "myapp_decisions_total: #{stats.dig(:decisions, :total)}"
      puts "myapp_decisions_avg_confidence: #{stats.dig(:decisions, :avg_confidence)&.round(3)}"
      puts "myapp_performance_avg_duration_ms: #{stats.dig(:performance, :avg_duration_ms)&.round(2)}"

      exporter
    end
  end

  # Example 6: Time Series Data
  class TimeSeriesData
    def self.run
      puts "\n" + "="*80
      puts "EXAMPLE 6: TIME SERIES (BUCKETED METRICS)"
      puts "="*80

      collector = DecisionAgent::Monitoring::MetricsCollector.new

      rules = {
        version: "1.0",
        ruleset: "recommendation",
        rules: [
          {
            id: "recommend",
            if: { field: "score", op: "gte", value: 0 },
            then: { decision: "recommended", weight: 0.8, reason: "Score based" }
          }
        ]
      }

      evaluator = DecisionAgent::Evaluators::JsonRuleEvaluator.new(rules_json: rules)
      agent = DecisionAgent::Agent.new(evaluators: [evaluator])
      monitored_agent = DecisionAgent::Monitoring::MonitoredAgent.new(
        agent: agent,
        metrics_collector: collector
      )

      puts "\nGenerating time series data..."
      50.times do |i|
        context = DecisionAgent::Context.new({ score: rand(0..100) })
        monitored_agent.decide(context: context)
        sleep(0.02)
      end

      # Get time series in 5-second buckets
      puts "\n--- Time Series (5-second buckets) ---"
      series = collector.time_series(
        metric_type: :decisions,
        bucket_size: 5,
        start_time: Time.now - 30
      )

      series.each do |bucket|
        puts "#{bucket[:timestamp]}: #{bucket[:count]} decisions, avg confidence: #{bucket[:avg_confidence]&.round(3)}"
      end

      collector
    end
  end

  # Main runner
  def self.run_all
    puts "\n" + "="*80
    puts "MONITORING ARCHITECTURE EXAMPLES"
    puts "Based on: wiki/MONITORING_ARCHITECTURE.md"
    puts "="*80

    examples = [
      AutomaticMonitoring,
      ManualMonitoring,
      ObserverPattern,
      AlertManagerDemo,
      PrometheusExport,
      TimeSeriesData
    ]

    examples.each_with_index do |example_class, index|
      example_class.run
      puts "\n[#{index + 1}/#{examples.length}] ✓ #{example_class.name} completed"

      if index < examples.length - 1
        puts "\nPress Enter to continue..."
        gets
      end
    end

    puts "\n" + "="*80
    puts "ALL EXAMPLES COMPLETED!"
    puts "="*80
  end
end

# Run if executed directly
if __FILE__ == $PROGRAM_NAME
  MonitoringSimpleExamples.run_all
end
