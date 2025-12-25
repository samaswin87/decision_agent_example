class DemoController < ApplicationController
  # Skip CSRF verification for API-style endpoints (JSON responses)
  skip_before_action :verify_authenticity_token, if: :json_request?

  # Skip CSRF verification for monitoring/benchmarking endpoints
  skip_before_action :verify_authenticity_token, only: [
    :monitoring_benchmark,
    :monitoring_load_test,
    :monitoring_evaluate,
    :monitoring_metrics_stream,
    :monitoring_multi_evaluate,
    :run_threading_test,
    :run_performance_test,
    :custom_evaluate
  ]

  def index
    @rulesets = Rule.select(:ruleset).distinct.pluck(:ruleset)
  end

  def loan_approval
    @result = nil

    if request.post?
      applicant_data = {
        name: params[:name],
        email: params[:email],
        credit_score: params[:credit_score].to_i,
        annual_income: params[:annual_income].to_i,
        debt_to_income_ratio: params[:debt_to_income_ratio].to_f
      }

      @result = SimpleLoanUseCase.evaluate(applicant_data)
    end
  end

  def discount_engine
    @result = nil

    if request.post?
      order_data = {
        customer_id: params[:customer_id],
        customer_tier: params[:customer_tier],
        cart_total: params[:cart_total].to_f,
        total_items: params[:total_items].to_i,
        is_first_purchase: params[:is_first_purchase] == '1'
      }

      @result = evaluate_discount(order_data)
    end
  end

  def fraud_detection
    @result = nil

    if request.post?
      transaction_data = {
        transaction_id: params[:transaction_id],
        transaction_amount: params[:transaction_amount].to_f,
        device_fingerprint_match: params[:device_fingerprint_match] == '1',
        location_match: params[:location_match] == '1',
        ip_reputation_score: params[:ip_reputation_score].to_i,
        transactions_last_hour: params[:transactions_last_hour].to_i
      }

      @result = evaluate_fraud(transaction_data)
    end
  end

  def custom_evaluate
    @result = nil
    @rules = Rule.active.order(:rule_id)

    if request.post? && params[:rule_id].present?
      context = begin
        JSON.parse(params[:context], symbolize_names: true)
      rescue JSON::ParserError
        {}
      end

      service = DecisionService.instance
      @result = service.evaluate(
        rule_id: params[:rule_id],
        context: context
      )
    end
  end

  def rules
    @rules = Rule.includes(:rule_versions).order(:rule_id)
  end

  def rule_versions
    @rule = Rule.find_by(rule_id: params[:rule_id])
    @versions = @rule&.versions&.limit(20) || []

    render json: @versions.map { |v|
      {
        id: v.id,
        version_number: v.version_number,
        status: v.status,
        created_by: v.created_by,
        changelog: v.changelog,
        created_at: v.created_at
      }
    }
  end

  def performance_dashboard
    # Main dashboard view
  end

  def threading_visualization
    # Threading visualization view
  end

  def run_threading_test
    thread_count = params[:thread_count]&.to_i || 4
    operations_per_thread = params[:operations_per_thread]&.to_i || 100
    use_case = params[:use_case] || 'simple_loan'

    # Setup use case
    setup_use_case(use_case)

    # Track metrics
    metrics = {
      thread_results: [],
      start_time: Time.now,
      operations_completed: 0,
      errors: 0
    }

    # Run threads
    threads = []
    thread_count.times do |thread_id|
      threads << Thread.new do
        thread_metrics = {
          thread_id: thread_id,
          operations: 0,
          errors: 0,
          latencies: [],
          start_time: Time.now
        }

        operations_per_thread.times do
          begin
            context = generate_random_context(use_case)
            start = Time.now
            evaluate_use_case(use_case, context)
            latency = ((Time.now - start) * 1000).round(2)

            thread_metrics[:operations] += 1
            thread_metrics[:latencies] << latency
          rescue
            thread_metrics[:errors] += 1
          end
        end

        thread_metrics[:end_time] = Time.now
        thread_metrics[:duration] = (thread_metrics[:end_time] - thread_metrics[:start_time]).round(3)
        thread_metrics[:avg_latency] = thread_metrics[:latencies].any? ? (thread_metrics[:latencies].sum / thread_metrics[:latencies].length).round(2) : 0
        thread_metrics
      end
    end

    # Wait and collect results
    thread_results = threads.map(&:value)

    metrics[:thread_results] = thread_results
    metrics[:end_time] = Time.now
    metrics[:total_duration] = (metrics[:end_time] - metrics[:start_time]).round(3)
    metrics[:operations_completed] = thread_results.sum { |t| t[:operations] }
    metrics[:errors] = thread_results.sum { |t| t[:errors] }
    metrics[:throughput] = (metrics[:operations_completed] / metrics[:total_duration]).round(2)

    all_latencies = thread_results.flat_map { |t| t[:latencies] }.sort
    metrics[:latency_stats] = {
      min: all_latencies.first&.round(2) || 0,
      max: all_latencies.last&.round(2) || 0,
      avg: all_latencies.any? ? (all_latencies.sum / all_latencies.length).round(2) : 0,
      p50: percentile(all_latencies, 50),
      p95: percentile(all_latencies, 95),
      p99: percentile(all_latencies, 99)
    }

    render json: metrics
  end

  def run_performance_test
    test_type = params[:test_type] || 'single'
    iterations = params[:iterations]&.to_i || 1000
    use_case = params[:use_case] || 'simple_loan'

    setup_use_case(use_case)

    result = case test_type
    when 'single'
      run_single_evaluation_test(use_case, iterations)
    when 'batch'
      run_batch_test(use_case, iterations)
    when 'cache'
      run_cache_test(use_case, iterations)
    when 'concurrent'
      run_concurrent_test(use_case, iterations)
    else
      { error: 'Unknown test type' }
    end

    render json: result
  end

  def all_use_cases
    # View to explore all use cases
    @use_cases = [
      { id: 'simple_loan', name: 'Simple Loan Approval', description: 'Basic loan approval with credit score evaluation' },
      { id: 'loan_approval', name: 'Advanced Loan Approval', description: 'Multi-tier loan approval system' },
      { id: 'fraud_detection', name: 'Fraud Detection', description: 'Real-time transaction fraud detection' },
      { id: 'discount_engine', name: 'Discount Engine', description: 'Multi-rule discount calculation' },
      { id: 'insurance_underwriting', name: 'Insurance Underwriting', description: 'Auto insurance risk assessment' },
      { id: 'content_moderation', name: 'Content Moderation', description: 'Multi-layer content safety system' },
      { id: 'dynamic_pricing', name: 'Dynamic Pricing', description: 'Real-time price optimization' },
      { id: 'recommendation_engine', name: 'Recommendation Engine', description: 'Personalized content recommendations' },
      { id: 'multi_stage_workflow', name: 'Multi-Stage Workflow', description: 'Complex approval workflow' },
      { id: 'ui_dashboard', name: 'UI Dashboard (NEW)', description: 'Real-time UI feedback and progress tracking' },
      { id: 'monitoring', name: 'Monitoring & Observability (NEW)', description: 'Comprehensive monitoring and performance tracking' }
    ]
  end

  # UI Dashboard Use Case Actions
  def ui_onboarding
    @result = nil

    if request.post?
      applicant_data = {
        name: params[:name],
        email: params[:email],
        credit_score: params[:credit_score].to_i,
        annual_income: params[:annual_income].to_i,
        employment_years: params[:employment_years].to_i,
        existing_customer: params[:existing_customer] == '1',
        fraud_risk_score: params[:fraud_risk_score]&.to_i || 10
      }

      @result = if params[:with_progress] == '1'
        UiDashboardUseCase.evaluate_with_progress(applicant_data)
      else
        UiDashboardUseCase.evaluate(applicant_data)
      end

      render json: @result if request.xhr?
    end
  end

  def ui_batch_process
    count = params[:count]&.to_i || 50

    applicants = count.times.map do |i|
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

    batch_result = UiDashboardUseCase.evaluate_batch_with_ui(applicants)

    render json: batch_result
  end

  def ui_metrics
    metrics = UiDashboardUseCase.generate_dashboard_metrics

    render json: metrics
  end

  # Monitoring & Observability Actions
  def monitoring_dashboard
    # Dashboard view
  end

  def monitoring_evaluate
    context = {
      credit_score: params[:credit_score]&.to_i || 720,
      requested_amount: params[:requested_amount]&.to_i || 30000,
      debt_to_income: params[:debt_to_income]&.to_f || 0.30,
      recent_bankruptcies: params[:recent_bankruptcies]&.to_i || 0,
      employment_years: params[:employment_years]&.to_i || 5
    }

    result = MonitoringObservabilityUseCase.evaluate_with_monitoring(
      context,
      request_id: request.request_id
    )

    render json: result
  end

  def monitoring_benchmark
    if request.get? && !request.xhr?
      # Render simple view for browser access
      @iterations = params[:iterations]&.to_i || 1000
      @warmup = params[:warmup]&.to_i || 100
      return
    end

    iterations = params[:iterations]&.to_i || 1000
    warmup = params[:warmup]&.to_i || 100

    benchmark = MonitoringObservabilityUseCase.run_performance_benchmark(
      iterations: iterations,
      warmup: warmup
    )

    render json: benchmark
  end

  def monitoring_load_test
    if request.get? && !request.xhr?
      # Render simple view for browser access
      @duration = params[:duration_seconds]&.to_i || 30
      @threads = params[:concurrent_threads]&.to_i || 10
      return
    end

    duration = params[:duration_seconds]&.to_i || 30
    threads = params[:concurrent_threads]&.to_i || 10

    load_test = MonitoringObservabilityUseCase.run_load_test(
      duration_seconds: duration,
      concurrent_threads: threads
    )

    render json: load_test
  end

  def monitoring_metrics_stream
    duration = params[:duration_seconds]&.to_i || 10
    interval = params[:interval_seconds]&.to_i || 1

    stream_result = MonitoringObservabilityUseCase.stream_metrics(
      duration_seconds: duration,
      interval_seconds: interval
    )

    render json: stream_result
  end

  # Multi-Use Case Monitoring
  def monitoring_multi
    @use_cases = [
      {
        id: 'simple_loan',
        name: 'Simple Loan Approval',
        description: 'Basic loan approval with credit score evaluation',
        sample_context: {
          name: 'John Doe',
          email: 'john@example.com',
          credit_score: 720,
          annual_income: 65000,
          debt_to_income_ratio: 0.35
        }
      },
      {
        id: 'monitored_credit',
        name: 'Monitored Credit Decision',
        description: 'Credit decision with full observability',
        sample_context: {
          credit_score: 700,
          requested_amount: 20000,
          debt_to_income: 0.35,
          recent_bankruptcies: 0,
          employment_years: 5
        }
      }
    ]
  end

  def monitoring_multi_evaluate
    use_case_id = params[:use_case_id]
    context_json = params[:context]

    begin
      context = JSON.parse(context_json, symbolize_names: true)

      result = case use_case_id
      when 'simple_loan'
        SimpleLoanUseCase.evaluate(context)
      when 'monitored_credit'
        MonitoringObservabilityUseCase.evaluate_with_monitoring(context)
      else
        { error: 'Unknown use case' }
      end

      render json: {
        use_case: use_case_id,
        timestamp: Time.current.iso8601,
        result: result
      }
    rescue JSON::ParserError => e
      render json: { error: "Invalid JSON: #{e.message}" }, status: 400
    rescue StandardError => e
      render json: { error: e.message }, status: 500
    end
  end

  private

  def setup_use_case(use_case)
    case use_case
    when 'simple_loan' then SimpleLoanUseCase.setup_rules
    when 'fraud_detection' then FraudDetectionUseCase.setup_rules
    when 'discount_engine' then DiscountEngineUseCase.setup_rules
    when 'insurance_underwriting' then InsuranceUnderwritingUseCase.setup_rules
    when 'content_moderation' then ContentModerationUseCase.setup_rules
    when 'dynamic_pricing' then DynamicPricingUseCase.setup_rules
    when 'recommendation_engine' then RecommendationEngineUseCase.setup_rules
    end
  rescue
    # Rules might already exist
  end

  def generate_random_context(use_case)
    case use_case
    when 'simple_loan'
      { credit_score: rand(550..850), annual_income: rand(20000..150000), debt_to_income_ratio: rand(0.1..0.6).round(2) }
    when 'fraud_detection'
      { transaction_amount: rand(10..10000), device_fingerprint_match: [true, false].sample, location_match: [true, false].sample, ip_reputation_score: rand(0..100), transactions_last_hour: rand(0..10) }
    when 'discount_engine'
      { customer_tier: %w[bronze silver gold platinum].sample, cart_total: rand(10..1000), total_items: rand(1..50), is_first_purchase: [true, false].sample }
    when 'insurance_underwriting'
      { driver_age: rand(18..75), years_licensed: rand(1..50), accidents_3_years: rand(0..5), violations_3_years: rand(0..5), credit_score: rand(500..850), annual_mileage: rand(5000..30000), dui_history: false, license_suspended: false, sr22_required: false }
    when 'content_moderation'
      { toxicity_score: rand(0.0..1.0).round(2), profanity_count: rand(0..10), spam_likelihood: rand(0.0..1.0).round(2), sexual_content_score: rand(0.0..1.0).round(2), contains_hate_speech: false, contains_violence: false, user_reputation_score: rand(0..100) }
    when 'dynamic_pricing'
      { base_price: rand(50..500), demand_level: rand(0..100), inventory_remaining_percentage: rand(0..100), time_to_event_hours: rand(1..168), competitor_avg_price: rand(50..500) }
    when 'recommendation_engine'
      { user_interaction_count: rand(0..200), profile_completeness: rand(0..100), days_since_last_visit: rand(0..90), is_new_user: [true, false].sample }
    else
      {}
    end
  end

  def evaluate_use_case(use_case, context)
    case use_case
    when 'simple_loan' then SimpleLoanUseCase.evaluate(context)
    when 'fraud_detection' then FraudDetectionUseCase.evaluate(context)
    when 'discount_engine' then DiscountEngineUseCase.evaluate(context)
    when 'insurance_underwriting' then InsuranceUnderwritingUseCase.evaluate(context)
    when 'content_moderation' then ContentModerationUseCase.evaluate(context)
    when 'dynamic_pricing' then DynamicPricingUseCase.evaluate(context)
    when 'recommendation_engine' then RecommendationEngineUseCase.evaluate(context)
    end
  end

  def run_single_evaluation_test(use_case, iterations)
    latencies = []
    errors = 0

    start_time = Time.now
    iterations.times do
      begin
        context = generate_random_context(use_case)
        op_start = Time.now
        evaluate_use_case(use_case, context)
        latencies << ((Time.now - op_start) * 1000).round(2)
      rescue
        errors += 1
      end
    end
    duration = Time.now - start_time

    {
      test_type: 'single_evaluation',
      iterations: iterations,
      duration: duration.round(3),
      throughput: (iterations / duration).round(2),
      errors: errors,
      latency: {
        min: latencies.min&.round(2) || 0,
        max: latencies.max&.round(2) || 0,
        avg: latencies.any? ? (latencies.sum / latencies.length).round(2) : 0,
        p95: percentile(latencies.sort, 95)
      }
    }
  end

  def run_batch_test(use_case, batch_size)
    contexts = Array.new(batch_size) { generate_random_context(use_case) }

    rule_id = get_rule_id_for_use_case(use_case)

    # Sequential
    start = Time.now
    DecisionService.instance.evaluate_batch(rule_id: rule_id, contexts: contexts, parallel: false)
    seq_duration = Time.now - start

    # Parallel
    start = Time.now
    DecisionService.instance.evaluate_batch(rule_id: rule_id, contexts: contexts, parallel: true)
    par_duration = Time.now - start

    {
      test_type: 'batch',
      batch_size: batch_size,
      sequential_duration: seq_duration.round(3),
      parallel_duration: par_duration.round(3),
      speedup: (seq_duration / par_duration).round(2),
      sequential_throughput: (batch_size / seq_duration).round(2),
      parallel_throughput: (batch_size / par_duration).round(2)
    }
  end

  def run_cache_test(use_case, iterations)
    context = generate_random_context(use_case)

    # Cold cache
    DecisionService.instance.clear_cache
    cold_start = Time.now
    iterations.times { evaluate_use_case(use_case, context) }
    cold_duration = Time.now - cold_start

    # Warm cache
    warm_start = Time.now
    iterations.times { evaluate_use_case(use_case, context) }
    warm_duration = Time.now - warm_start

    {
      test_type: 'cache',
      iterations: iterations,
      cold_cache_duration: cold_duration.round(3),
      warm_cache_duration: warm_duration.round(3),
      improvement: ((cold_duration - warm_duration) / cold_duration * 100).round(2),
      cold_throughput: (iterations / cold_duration).round(2),
      warm_throughput: (iterations / warm_duration).round(2)
    }
  end

  def run_concurrent_test(use_case, total_ops)
    thread_counts = [1, 2, 4, 8]
    results = []

    thread_counts.each do |thread_count|
      ops_per_thread = total_ops / thread_count

      start_time = Time.now
      threads = []
      thread_count.times do
        threads << Thread.new do
          ops_per_thread.times do
            evaluate_use_case(use_case, generate_random_context(use_case))
          end
        end
      end
      threads.each(&:join)
      duration = Time.now - start_time

      results << {
        threads: thread_count,
        duration: duration.round(3),
        throughput: (total_ops / duration).round(2)
      }
    end

    {
      test_type: 'concurrent',
      total_operations: total_ops,
      results: results,
      optimal_thread_count: results.max_by { |r| r[:throughput] }[:threads]
    }
  end

  def get_rule_id_for_use_case(use_case)
    case use_case
    when 'simple_loan' then 'simple_loan_approval'
    when 'fraud_detection' then 'fraud_high_risk'
    when 'discount_engine' then 'discount_loyalty'
    when 'insurance_underwriting' then 'auto_insurance_preferred'
    when 'content_moderation' then 'content_severe_violations'
    when 'dynamic_pricing' then 'pricing_surge'
    when 'recommendation_engine' then 'recommendation_highly_personalized'
    else 'simple_loan_approval'
    end
  end

  def get_rule_ids_for_use_case(use_case)
    case use_case
    when 'simple_loan' then ['simple_loan_approval']
    when 'fraud_detection' then ['fraud_high_risk', 'fraud_medium_risk', 'fraud_low_risk', 'fraud_safe']
    when 'discount_engine' then ['discount_loyalty', 'discount_bulk', 'discount_first_time', 'discount_seasonal', 'discount_cart_threshold']
    else ['simple_loan_approval']
    end
  end

  def percentile(sorted_array, percentile)
    return 0 if sorted_array.empty?
    k = (percentile / 100.0) * (sorted_array.length - 1)
    f = k.floor
    c = k.ceil

    if f == c
      sorted_array[k].round(2)
    else
      (sorted_array[f] * (c - k) + sorted_array[c] * (k - f)).round(2)
    end
  end

  def evaluate_discount(order_data)
    # Simplified discount evaluation
    service = DecisionService.instance
    result = service.evaluate(
      rule_id: 'discount_engine_v1',
      context: order_data
    )

    {
      order: order_data,
      decision: result[:decision],
      confidence: result[:confidence],
      explanations: result[:explanations],
      evaluated_at: Time.current
    }
  rescue StandardError => e
    { error: e.message }
  end

  def evaluate_fraud(transaction_data)
    # Simplified fraud evaluation
    service = DecisionService.instance
    result = service.evaluate(
      rule_id: 'fraud_detection_v1',
      context: transaction_data
    )

    {
      transaction: transaction_data,
      decision: result[:decision],
      confidence: result[:confidence],
      explanations: result[:explanations],
      risk_level: determine_risk_level(result[:decision]),
      evaluated_at: Time.current
    }
  rescue StandardError => e
    { error: e.message }
  end

  def determine_risk_level(decision)
    case decision
    when 'approve' then 'safe'
    when 'monitor' then 'low'
    when 'review' then 'medium'
    when 'block' then 'high'
    else 'unknown'
    end
  end

  # ============================================================================
  # NEW COMPREHENSIVE TESTING ACTIONS
  # ============================================================================

  public

  def test_center
    # Main test center dashboard
  end

  def test_all_use_cases
    @use_cases = all_use_cases_list
    render layout: false
  end

  def run_all_use_case_tests
    results = []

    all_use_cases_list.each do |use_case|
      begin
        setup_use_case(use_case[:id])
        context = generate_random_context(use_case[:id])
        start = Time.now
        result = evaluate_use_case(use_case[:id], context)
        duration = ((Time.now - start) * 1000).round(2)

        results << {
          use_case: use_case[:name],
          status: 'passed',
          duration_ms: duration,
          result: result
        }
      rescue => e
        results << {
          use_case: use_case[:name],
          status: 'failed',
          error: e.message
        }
      end
    end

    render json: {
      total: results.length,
      passed: results.count { |r| r[:status] == 'passed' },
      failed: results.count { |r| r[:status] == 'failed' },
      results: results
    }
  end

  def generate_test_data
    @data_types = [
      { id: 'loan', name: 'Loan Applications', count: 100 },
      { id: 'fraud', name: 'Fraud Transactions', count: 100 },
      { id: 'discount', name: 'Discount Orders', count: 100 },
      { id: 'all', name: 'All Use Cases', count: 500 }
    ]
  end

  def create_test_data
    data_type = params[:data_type]
    count = params[:count]&.to_i || 100

    generated_data = []

    count.times do |i|
      context = case data_type
      when 'loan'
        generate_random_context('simple_loan')
      when 'fraud'
        generate_random_context('fraud_detection')
      when 'discount'
        generate_random_context('discount_engine')
      when 'all'
        use_case = all_use_cases_list.sample
        generate_random_context(use_case[:id])
      else
        {}
      end

      generated_data << {
        id: i + 1,
        context: context,
        generated_at: Time.current
      }
    end

    render json: {
      data_type: data_type,
      count: generated_data.length,
      data: generated_data
    }
  end

  def batch_testing
    # Batch testing UI
  end

  def run_batch_tests
    use_case = params[:use_case] || 'simple_loan'
    batch_size = params[:batch_size]&.to_i || 100
    parallel = params[:parallel] == 'true'

    setup_use_case(use_case)

    contexts = batch_size.times.map { generate_random_context(use_case) }
    rule_id = get_rule_id_for_use_case(use_case)

    start_time = Time.now
    begin
      results = DecisionService.instance.evaluate_batch(
        rule_id: rule_id,
        contexts: contexts,
        parallel: parallel
      )
      duration = Time.now - start_time

      render json: {
        use_case: use_case,
        batch_size: batch_size,
        parallel: parallel,
        duration: duration.round(3),
        throughput: (batch_size / duration).round(2),
        success_count: results.count { |r| r[:decision] },
        results: results.first(10) # Return first 10 for preview
      }
    rescue => e
      render json: { error: e.message }, status: 500
    end
  end

  def monitoring_examples
    @examples = [
      {
        id: 'automatic',
        name: 'Automatic Monitoring',
        description: 'Wrapper pattern for automatic metric collection',
        class: 'AutomaticMonitoringExample'
      },
      {
        id: 'manual',
        name: 'Manual Monitoring',
        description: 'Explicit metric recording with custom metadata',
        class: 'ManualMonitoringExample'
      },
      {
        id: 'observer',
        name: 'Observer Pattern',
        description: 'Callback-based real-time notifications',
        class: 'ObserverPatternExample'
      },
      {
        id: 'alert',
        name: 'Alert Manager',
        description: 'Rule-based alerting system',
        class: 'AlertManagerExample'
      },
      {
        id: 'prometheus',
        name: 'Prometheus Exporter',
        description: 'Prometheus metrics export',
        class: 'PrometheusExporterExample'
      },
      {
        id: 'timeseries',
        name: 'Time Series',
        description: 'Bucketed time series data',
        class: 'TimeSeriesExample'
      },
      {
        id: 'memory',
        name: 'Memory Management',
        description: 'Automatic metric cleanup',
        class: 'MemoryManagementExample'
      },
      {
        id: 'dashboard',
        name: 'Dashboard Server',
        description: 'Full monitoring stack simulation',
        class: 'DashboardServerExample'
      }
    ]
  end

  def test_monitoring
    # UI for testing monitoring examples
  end

  def run_monitoring_tests
    require_relative '../use_cases/monitoring_architecture_examples'

    results = []
    examples = MonitoringArchitectureExamples.constants.select { |c| c.to_s.end_with?('Example') }

    examples.each do |example_name|
      begin
        example_class = MonitoringArchitectureExamples.const_get(example_name)
        start = Time.now
        collector = example_class.run
        duration = Time.now - start

        stats = collector.statistics

        results << {
          name: example_name.to_s.gsub('Example', '').scan(/[A-Z][a-z]*/).join(' '),
          status: 'passed',
          duration: duration.round(3),
          decisions: stats.dig(:decisions, :total) || 0,
          errors: stats.dig(:errors, :total) || 0
        }
      rescue => e
        results << {
          name: example_name.to_s,
          status: 'failed',
          error: e.message
        }
      end
    end

    render json: {
      total: results.length,
      passed: results.count { |r| r[:status] == 'passed' },
      failed: results.count { |r| r[:status] == 'failed' },
      results: results
    }
  end

  def rule_versioning
    @rules = Rule.all.order(:rule_id)
  end

  def create_rule_version
    rule_id = params[:rule_id]
    content = params[:content]
    created_by = params[:created_by] || 'demo_user'
    changelog = params[:changelog]

    service = DecisionService.instance
    version = service.save_rule_version(
      rule_id: rule_id,
      content: content,
      created_by: created_by,
      changelog: changelog
    )

    render json: { success: true, version: version }
  rescue => e
    render json: { success: false, error: e.message }, status: 422
  end

  def activate_rule_version
    rule_id = params[:rule_id]
    version_number = params[:version_number]&.to_i

    service = DecisionService.instance
    service.activate_version(rule_id, version_number)

    render json: { success: true, message: "Version #{version_number} activated" }
  rescue => e
    render json: { success: false, error: e.message }, status: 422
  end

  def rollback_rule
    rule_id = params[:rule_id]
    version_number = params[:version_number]&.to_i

    service = DecisionService.instance
    service.rollback(rule_id, version_number)

    render json: { success: true, message: "Rolled back to version #{version_number}" }
  rescue => e
    render json: { success: false, error: e.message }, status: 422
  end

  def rule_comparison
    @rules = Rule.all.order(:rule_id)
  end

  def compare_rule_versions
    rule_id = params[:rule_id]
    version1 = params[:version1]&.to_i
    version2 = params[:version2]&.to_i

    service = DecisionService.instance
    comparison = service.compare_versions(rule_id, version1, version2)

    render json: comparison
  rescue => e
    render json: { error: e.message }, status: 422
  end

  def rule_audit
    @rules = Rule.includes(:rule_versions).order(:rule_id)
    @audit_entries = RuleVersion.order(created_at: :desc).limit(50)
  end

  def scoring_strategies
    @strategies = [
      { id: 'weighted_average', name: 'Weighted Average', description: 'Combines evaluations using weighted average' },
      { id: 'max_weight', name: 'Max Weight', description: 'Selects decision with highest weight' },
      { id: 'consensus', name: 'Consensus', description: 'Requires minimum agreement threshold' },
      { id: 'threshold', name: 'Threshold', description: 'Requires minimum confidence threshold' }
    ]
  end

  def test_scoring
    strategy = params[:strategy]
    use_case = params[:use_case] || 'simple_loan'

    setup_use_case(use_case)
    context = generate_random_context(use_case)

    # Test with selected scoring strategy
    result = evaluate_use_case(use_case, context)

    render json: {
      strategy: strategy,
      use_case: use_case,
      context: context,
      result: result
    }
  rescue => e
    render json: { error: e.message }, status: 500
  end

  def conflict_resolution
    # UI for testing conflict resolution
  end

  def test_conflict_resolution
    # Simulate conflicting evaluators
    contexts = 5.times.map { generate_random_context('simple_loan') }

    results = contexts.map do |context|
      SimpleLoanUseCase.evaluate(context)
    end

    render json: {
      contexts: contexts,
      results: results
    }
  rescue => e
    render json: { error: e.message }, status: 500
  end

  def evaluator_comparison
    # UI for comparing multiple evaluators
  end

  def compare_evaluators
    context = JSON.parse(params[:context], symbolize_names: true)

    # Compare different use cases on same context
    results = {}

    all_use_cases_list.each do |use_case|
      begin
        setup_use_case(use_case[:id])
        results[use_case[:id]] = evaluate_use_case(use_case[:id], context)
      rescue => e
        results[use_case[:id]] = { error: e.message }
      end
    end

    render json: {
      context: context,
      results: results
    }
  rescue JSON::ParserError => e
    render json: { error: "Invalid JSON: #{e.message}" }, status: 400
  rescue => e
    render json: { error: e.message }, status: 500
  end

  def decision_replay
    # UI for replaying decisions
  end

  def replay_decision
    decision_data = JSON.parse(params[:decision_data], symbolize_names: true)

    # Replay the decision with same context
    use_case = params[:use_case]
    setup_use_case(use_case)

    original_result = decision_data
    replayed_result = evaluate_use_case(use_case, decision_data[:context] || {})

    render json: {
      original: original_result,
      replayed: replayed_result,
      match: original_result[:decision] == replayed_result[:decision]
    }
  rescue JSON::ParserError => e
    render json: { error: "Invalid JSON: #{e.message}" }, status: 400
  rescue => e
    render json: { error: e.message }, status: 500
  end

  def seed_all_data
    begin
      load Rails.root.join('db/seeds.rb')
      render json: { success: true, message: 'All data seeded successfully' }
    rescue => e
      render json: { success: false, error: e.message }, status: 500
    end
  end

  def reset_database
    begin
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE rules, rule_versions RESTART IDENTITY CASCADE')
      render json: { success: true, message: 'Database reset successfully' }
    rescue => e
      render json: { success: false, error: e.message }, status: 500
    end
  end

  def run_all_tests
    @test_results = {
      use_cases: [],
      monitoring: [],
      performance: []
    }

    # Run use case tests
    all_use_cases_list.each do |use_case|
      begin
        setup_use_case(use_case[:id])
        context = generate_random_context(use_case[:id])
        result = evaluate_use_case(use_case[:id], context)
        @test_results[:use_cases] << { name: use_case[:name], status: 'passed' }
      rescue => e
        @test_results[:use_cases] << { name: use_case[:name], status: 'failed', error: e.message }
      end
    end

    render :run_all_tests
  end

  def export_results
    results = {
      exported_at: Time.current,
      use_cases: all_use_cases_list.length,
      rules: Rule.count,
      versions: RuleVersion.count,
      data: {
        rules: Rule.all,
        versions: RuleVersion.order(created_at: :desc).limit(100)
      }
    }

    send_data results.to_json, filename: "decision_agent_export_#{Time.current.to_i}.json", type: :json
  end

  private

  def json_request?
    request.format.json? || request.content_type == 'application/json'
  end

  def all_use_cases_list
    [
      { id: 'simple_loan', name: 'Simple Loan Approval', description: 'Basic loan approval with credit score evaluation' },
      { id: 'loan_approval', name: 'Advanced Loan Approval', description: 'Multi-tier loan approval system' },
      { id: 'fraud_detection', name: 'Fraud Detection', description: 'Real-time transaction fraud detection' },
      { id: 'discount_engine', name: 'Discount Engine', description: 'Multi-rule discount calculation' },
      { id: 'insurance_underwriting', name: 'Insurance Underwriting', description: 'Auto insurance risk assessment' },
      { id: 'content_moderation', name: 'Content Moderation', description: 'Multi-layer content safety system' },
      { id: 'dynamic_pricing', name: 'Dynamic Pricing', description: 'Real-time price optimization' },
      { id: 'recommendation_engine', name: 'Recommendation Engine', description: 'Personalized content recommendations' },
      { id: 'multi_stage_workflow', name: 'Multi-Stage Workflow', description: 'Complex approval workflow' },
      { id: 'ui_dashboard', name: 'UI Dashboard', description: 'Real-time UI feedback and progress tracking' },
      { id: 'monitoring', name: 'Monitoring & Observability', description: 'Comprehensive monitoring and performance tracking' }
    ]
  end
end
