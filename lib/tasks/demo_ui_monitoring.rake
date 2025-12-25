namespace :demo do
  namespace :ui do
    desc "Demo: UI Dashboard Use Case - Interactive onboarding decisions"
    task onboarding: :environment do
      puts "\n" + "="*80
      puts "UI DASHBOARD USE CASE - Customer Onboarding with Real-time Feedback"
      puts "="*80 + "\n"

      # Example 1: Premium customer - instant approval
      puts "\n--- Example 1: Premium Customer (Instant Approval) ---"
      applicant1 = {
        name: "Sarah Johnson",
        email: "sarah.johnson@example.com",
        credit_score: 780,
        annual_income: 120000,
        employment_years: 5,
        existing_customer: true,
        fraud_risk_score: 5
      }

      result1 = UiDashboardUseCase.evaluate(applicant1)
      display_ui_result(result1)

      # Example 2: Fast track customer
      puts "\n--- Example 2: Fast Track Customer ---"
      applicant2 = {
        name: "Michael Chen",
        email: "m.chen@example.com",
        credit_score: 720,
        annual_income: 75000,
        employment_years: 3,
        existing_customer: false,
        fraud_risk_score: 12
      }

      result2 = UiDashboardUseCase.evaluate(applicant2)
      display_ui_result(result2)

      # Example 3: Standard review required
      puts "\n--- Example 3: Standard Review Required ---"
      applicant3 = {
        name: "Jennifer Martinez",
        email: "j.martinez@example.com",
        credit_score: 670,
        annual_income: 45000,
        employment_years: 2,
        existing_customer: false,
        fraud_risk_score: 25
      }

      result3 = UiDashboardUseCase.evaluate(applicant3)
      display_ui_result(result3)

      # Example 4: Progress tracking
      puts "\n--- Example 4: Evaluation with Progress Tracking (for UI) ---"
      result_with_progress = UiDashboardUseCase.evaluate_with_progress(applicant1)

      puts "\nProgress Steps:"
      result_with_progress[:progress_steps].each do |step|
        puts "  #{step[:step]}. #{step[:name]} - #{step[:status].upcase} (#{step[:duration_ms]}ms)"
        puts "     Data: #{step[:data]}" if step[:data]
      end

      # Example 5: Batch processing with progress
      puts "\n--- Example 5: Batch Processing (100 applicants) ---"
      applicants = 100.times.map do |i|
        {
          name: "Applicant #{i+1}",
          email: "applicant#{i+1}@example.com",
          credit_score: rand(550..850),
          annual_income: rand(30000..150000),
          employment_years: rand(0..20),
          existing_customer: [true, false].sample,
          fraud_risk_score: rand(1..100)
        }
      end

      batch_result = UiDashboardUseCase.evaluate_batch_with_ui(applicants) do |progress|
        print "\rProcessing: #{progress[:percentage]}% (#{progress[:completed]}/#{progress[:total]})"
      end

      puts "\n\nBatch Summary:"
      puts "  Total Processed: #{batch_result[:total_processed]}"
      puts "  Summary: #{batch_result[:summary].to_json}"

      # Example 6: Dashboard metrics
      puts "\n--- Example 6: Dashboard Metrics ---"
      metrics = UiDashboardUseCase.generate_dashboard_metrics

      puts "\nDashboard Summary (#{metrics[:period]}):"
      puts "  Total Applications: #{metrics[:total_applications]}"
      puts "\nDecisions Breakdown:"
      metrics[:decisions].each do |decision, stats|
        puts "  #{decision.to_s.titleize}:"
        puts "    Count: #{stats[:count]} (#{stats[:percentage]}%)"
        puts "    Trend: #{stats[:trend]}"
      end

      puts "\nPerformance Metrics:"
      puts "  Average Decision Time: #{metrics[:average_decision_time_ms]}ms"
      puts "  P50 Latency: #{metrics[:performance][:p50_latency_ms]}ms"
      puts "  P95 Latency: #{metrics[:performance][:p95_latency_ms]}ms"
      puts "  P99 Latency: #{metrics[:performance][:p99_latency_ms]}ms"
      puts "  Error Rate: #{metrics[:performance][:error_rate]}%"

      puts "\n" + "="*80
      puts "Demo completed successfully!"
      puts "="*80 + "\n"
    end

    def display_ui_result(result)
      puts "\nApplicant: #{result[:applicant][:name]} (#{result[:applicant][:email]})"
      puts "Decision: #{result[:decision].upcase}"
      puts "Confidence: #{result[:decision_details][:confidence_percentage]}%"
      puts "\nUI Feedback:"
      puts "  Status: #{result[:ui][:status_icon]} (#{result[:ui][:status_color]})"
      puts "  Next Step: #{result[:ui][:next_step]}"
      puts "  Estimated Time: #{result[:ui][:estimated_time] || 'N/A'}"

      if result[:ui][:required_documents].any?
        puts "  Required Documents:"
        result[:ui][:required_documents].each { |doc| puts "    - #{doc}" }
      end

      if result[:ui][:benefits].any?
        puts "  Benefits:"
        result[:ui][:benefits].each { |benefit| puts "    - #{benefit}" }
      end

      if result[:ui][:tips].any?
        puts "  Tips:"
        result[:ui][:tips].each { |tip| puts "    - #{tip}" }
      end

      puts "\nPerformance: #{result[:metadata][:evaluation_time_ms]}ms"
    end
  end

  namespace :monitoring do
    desc "Demo: Monitoring & Observability Use Case"
    task observability: :environment do
      puts "\n" + "="*80
      puts "MONITORING & OBSERVABILITY USE CASE"
      puts "="*80 + "\n"

      # Example 1: Single evaluation with monitoring
      puts "--- Example 1: Single Evaluation with Full Monitoring ---"
      context1 = {
        credit_score: 750,
        requested_amount: 30000,
        debt_to_income: 0.28,
        recent_bankruptcies: 0,
        employment_years: 5
      }

      result1 = MonitoringObservabilityUseCase.evaluate_with_monitoring(context1)
      display_monitoring_result(result1)

      # Example 2: High risk scenario (should trigger alerts)
      puts "\n--- Example 2: High Risk Scenario (Alert Triggering) ---"
      context2 = {
        credit_score: 620,
        requested_amount: 50000,
        debt_to_income: 0.52,
        recent_bankruptcies: 1,
        employment_years: 1
      }

      result2 = MonitoringObservabilityUseCase.evaluate_with_monitoring(context2)
      display_monitoring_result(result2)

      # Example 3: Performance benchmark
      puts "\n--- Example 3: Performance Benchmark (1000 iterations) ---"
      puts "Running performance benchmark..."

      benchmark = MonitoringObservabilityUseCase.run_performance_benchmark(
        iterations: 1000,
        warmup: 100
      )

      puts "\nBenchmark Results:"
      puts "  Total Duration: #{benchmark[:total_duration_seconds]}s"
      puts "  Throughput: #{benchmark[:test_phase][:throughput_per_second]} requests/sec"

      puts "\nLatency Statistics:"
      stats = benchmark[:test_phase][:latency_stats]
      puts "  Min:        #{stats[:min_ms]}ms"
      puts "  Mean:       #{stats[:mean_ms]}ms"
      puts "  Median:     #{stats[:median_ms]}ms"
      puts "  P95:        #{stats[:p95_ms]}ms"
      puts "  P99:        #{stats[:p99_ms]}ms"
      puts "  P99.9:      #{stats[:p999_ms]}ms"
      puts "  Max:        #{stats[:max_ms]}ms"
      puts "  Std Dev:    #{stats[:std_dev]}ms"

      puts "\nMemory Analysis:"
      puts "  Samples: #{benchmark[:test_phase][:memory_analysis][:samples].size}"
      puts "  Trend: #{benchmark[:test_phase][:memory_analysis][:trend]}MB"

      if benchmark[:detailed_metrics].any?
        puts "\nOutliers (>100ms): #{benchmark[:detailed_metrics].size}"
        puts "  Slowest iteration: #{benchmark[:detailed_metrics].max_by { |m| m[:latency_ms] }[:latency_ms]}ms"
      end

      # Example 4: Load test
      puts "\n--- Example 4: Concurrent Load Test (10 threads, 30 seconds) ---"
      puts "Running load test..."

      load_test = MonitoringObservabilityUseCase.run_load_test(
        duration_seconds: 30,
        concurrent_threads: 10
      )

      puts "\nLoad Test Results:"
      puts "  Duration: #{load_test[:aggregate_metrics][:actual_duration_seconds]}s"
      puts "  Total Requests: #{load_test[:aggregate_metrics][:total_requests]}"
      puts "  Total Errors: #{load_test[:aggregate_metrics][:total_errors]}"
      puts "  Error Rate: #{load_test[:aggregate_metrics][:error_rate]}%"
      puts "  Throughput: #{load_test[:aggregate_metrics][:throughput_per_second]} req/sec"

      puts "\nLatency Percentiles:"
      load_test[:aggregate_metrics][:latency_percentiles].each do |percentile, value|
        puts "  #{percentile}: #{value}ms"
      end

      puts "\nDecisions Breakdown:"
      load_test[:aggregate_metrics][:decisions_breakdown].each do |decision, count|
        percentage = (count.to_f / load_test[:aggregate_metrics][:total_requests] * 100).round(2)
        puts "  #{decision}: #{count} (#{percentage}%)"
      end

      puts "\nPer-Thread Performance:"
      load_test[:thread_metrics].each do |tm|
        avg_latency = tm[:latencies].any? ? (tm[:latencies].sum / tm[:latencies].size).round(3) : 0
        puts "  Thread #{tm[:thread_id]}: #{tm[:requests]} requests, #{tm[:errors]} errors, avg latency: #{avg_latency}ms"
      end

      puts "\n" + "="*80
      puts "Monitoring demo completed successfully!"
      puts "All metrics logged and available for analysis"
      puts "="*80 + "\n"
    end

    desc "Demo: Real-time metrics streaming"
    task stream_metrics: :environment do
      puts "\n" + "="*80
      puts "REAL-TIME METRICS STREAMING DEMO"
      puts "="*80 + "\n"

      puts "Streaming metrics for 10 seconds (1-second intervals)..."
      puts "Watch the console for real-time metric updates\n"

      stream_result = MonitoringObservabilityUseCase.stream_metrics(
        duration_seconds: 10,
        interval_seconds: 1
      )

      puts "\n\nStreaming Summary:"
      puts "  Duration: #{stream_result[:test_duration_seconds]}s"
      puts "  Total Requests: #{stream_result[:summary][:total_requests]}"
      puts "  Avg Throughput: #{stream_result[:summary][:avg_throughput]} req/sec"
      puts "  Avg Latency: #{stream_result[:summary][:avg_latency_ms]}ms"

      puts "\nInterval-by-Interval Metrics:"
      stream_result[:metrics].each do |metric|
        puts "  Interval #{metric[:interval]}: #{metric[:requests]} requests, " \
             "#{metric[:requests_per_second]} req/s, " \
             "avg latency: #{metric[:avg_latency_ms]}ms, " \
             "max latency: #{metric[:max_latency_ms]}ms"
      end

      puts "\n" + "="*80
    end

    def display_monitoring_result(result)
      puts "\nRequest ID: #{result[:request_id]}"
      puts "Decision: #{result[:decision]} (Confidence: #{(result[:confidence] * 100).round(2)}%)"
      puts "Explanation: #{result[:explanations].first}"

      puts "\nPerformance:"
      puts "  Evaluation Time: #{result[:performance][:evaluation_time_ms]}ms"
      puts "  SLA Target: #{result[:performance][:sla_target_ms]}ms"
      puts "  SLA Breached: #{result[:performance][:sla_breached]}"
      puts "  Context Size: #{result[:performance][:context_size_bytes]} bytes"

      puts "\nMonitoring:"
      puts "  Rules Evaluated: #{result[:monitoring][:rules_evaluated]}"
      puts "  Category: #{result[:monitoring][:category]}"
      puts "  Business Impact: #{result[:monitoring][:business_impact]}"

      puts "\nAudit Trail:"
      puts "  Rule ID: #{result[:audit][:rule_id]}"
      puts "  Rule Version: #{result[:audit][:rule_version]}"
      puts "  Context Hash: #{result[:audit][:context_hash]}"
      puts "  Evaluated At: #{result[:audit][:evaluated_at]}"
    end
  end

  desc "Demo: Run all UI and monitoring examples"
  task all: :environment do
    Rake::Task['demo:ui:onboarding'].invoke
    puts "\n\n"
    Rake::Task['demo:monitoring:observability'].invoke
  end
end
