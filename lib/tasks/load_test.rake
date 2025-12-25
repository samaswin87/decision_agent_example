namespace :load_test do
  desc "Run configurable load test scenarios"
  task :run, [:scenario, :duration, :threads] => :environment do |_t, args|
    require 'benchmark'

    scenario = args[:scenario] || 'medium'
    duration = (args[:duration] || 60).to_i # seconds
    thread_count = (args[:thread_count] || 4).to_i

    puts "\n" + "="*80
    puts "LOAD TESTING - Decision Agent"
    puts "="*80
    puts "Scenario: #{scenario.upcase}"
    puts "Duration: #{duration} seconds"
    puts "Threads: #{thread_count}"
    puts "="*80 + "\n"

    # Load scenario configuration
    config = get_scenario_config(scenario)

    puts "📋 Scenario Configuration:"
    puts "   Operations per thread: #{config[:operations_per_thread]}"
    puts "   Use cases: #{config[:use_cases].join(', ')}"
    puts "   Parallel batch processing: #{config[:parallel_batching]}"
    puts "   Cache warming: #{config[:warm_cache]}"
    puts "\n"

    # Setup
    puts "🔧 Setting up test environment..."
    setup_use_cases(config[:use_cases])

    if config[:warm_cache]
      puts "🔥 Warming cache..."
      warm_cache(config[:use_cases])
    end

    puts "\n🚀 Starting load test...\n"

    # Tracking metrics
    metrics = {
      start_time: Time.now,
      operations_completed: Concurrent::AtomicFixnum.new(0),
      errors: Concurrent::AtomicFixnum.new(0),
      latencies: Concurrent::Array.new
    }

    # Run load test
    threads = []
    start_time = Time.now

    thread_count.times do |thread_id|
      threads << Thread.new do
        thread_metrics = run_thread_workload(thread_id, config, metrics, start_time, duration)
        thread_metrics
      end
    end

    # Monitor progress
    monitor_thread = Thread.new do
      monitor_progress(metrics, start_time, duration)
    end

    # Wait for completion
    thread_results = threads.map(&:value)
    monitor_thread.kill

    # Calculate final metrics
    end_time = Time.now
    actual_duration = end_time - start_time

    puts "\n\n" + "="*80
    puts "LOAD TEST RESULTS"
    puts "="*80

    total_operations = metrics[:operations_completed].value
    total_errors = metrics[:errors].value
    latencies = metrics[:latencies].to_a.sort

    puts "\n📊 Overall Statistics:"
    puts "   Total operations: #{total_operations}"
    puts "   Successful: #{total_operations - total_errors}"
    puts "   Errors: #{total_errors}"
    puts "   Success rate: #{((total_operations - total_errors).to_f / total_operations * 100).round(2)}%"
    puts "   Duration: #{actual_duration.round(2)}s"
    puts "   Throughput: #{(total_operations / actual_duration).round(2)} ops/sec"

    if latencies.any?
      puts "\n⏱️  Latency Statistics (ms):"
      puts "   Min: #{latencies.first.round(2)}"
      puts "   Max: #{latencies.last.round(2)}"
      puts "   Mean: #{(latencies.sum / latencies.length).round(2)}"
      puts "   Median (P50): #{percentile(latencies, 50).round(2)}"
      puts "   P90: #{percentile(latencies, 90).round(2)}"
      puts "   P95: #{percentile(latencies, 95).round(2)}"
      puts "   P99: #{percentile(latencies, 99).round(2)}"
    end

    puts "\n🧵 Thread Statistics:"
    thread_results.each_with_index do |result, index|
      puts "   Thread #{index + 1}: #{result[:operations]} ops, #{result[:errors]} errors"
    end

    # Save results
    results = {
      scenario: scenario,
      configuration: config,
      duration: actual_duration,
      threads: thread_count,
      total_operations: total_operations,
      successful_operations: total_operations - total_errors,
      errors: total_errors,
      success_rate: ((total_operations - total_errors).to_f / total_operations * 100).round(2),
      throughput: (total_operations / actual_duration).round(2),
      latencies: {
        min: latencies.first&.round(2),
        max: latencies.last&.round(2),
        mean: latencies.any? ? (latencies.sum / latencies.length).round(2) : 0,
        p50: latencies.any? ? percentile(latencies, 50).round(2) : 0,
        p90: latencies.any? ? percentile(latencies, 90).round(2) : 0,
        p95: latencies.any? ? percentile(latencies, 95).round(2) : 0,
        p99: latencies.any? ? percentile(latencies, 99).round(2) : 0
      },
      thread_results: thread_results
    }

    filename = "load_test_results_#{scenario}_#{Time.now.strftime('%Y%m%d_%H%M%S')}.json"
    File.write(filename, JSON.pretty_generate(results))

    puts "\n💾 Results saved to: #{filename}"
    puts "\n" + "="*80
    puts "Load test complete! 🎉"
    puts "="*80 + "\n"
  end

  desc "Run stress test to find breaking point"
  task stress_test: :environment do
    puts "\n" + "="*80
    puts "STRESS TEST - Finding Breaking Point"
    puts "="*80 + "\n"

    setup_use_cases(['simple_loan'])

    thread_increments = [1, 2, 4, 8, 16, 32, 64]
    results = []

    thread_increments.each do |thread_count|
      puts "\n🧵 Testing with #{thread_count} threads..."

      GC.start
      metrics = {
        operations_completed: Concurrent::AtomicFixnum.new(0),
        errors: Concurrent::AtomicFixnum.new(0),
        latencies: Concurrent::Array.new
      }

      start_time = Time.now
      duration = 30 # 30 seconds per test

      threads = []
      thread_count.times do
        threads << Thread.new do
          end_time = start_time + duration
          ops = 0
          errors = 0

          while Time.now < end_time
            begin
              context = generate_random_loan_context
              op_start = Time.now
              SimpleLoanUseCase.evaluate(context)
              latency = (Time.now - op_start) * 1000
              metrics[:latencies] << latency
              metrics[:operations_completed].increment
              ops += 1
            rescue => e
              metrics[:errors].increment
              errors += 1
            end
          end

          { operations: ops, errors: errors }
        end
      end

      threads.each(&:join)

      actual_duration = Time.now - start_time
      total_ops = metrics[:operations_completed].value
      throughput = total_ops / actual_duration
      error_rate = (metrics[:errors].value.to_f / total_ops * 100).round(2)
      latencies = metrics[:latencies].to_a.sort
      p95_latency = latencies.any? ? percentile(latencies, 95) : 0

      result = {
        threads: thread_count,
        throughput: throughput.round(2),
        p95_latency: p95_latency.round(2),
        error_rate: error_rate
      }
      results << result

      puts "   Throughput: #{result[:throughput]} ops/sec"
      puts "   P95 Latency: #{result[:p95_latency]}ms"
      puts "   Error Rate: #{result[:error_rate]}%"

      # Check if system is degrading
      if error_rate > 5.0 || p95_latency > 1000
        puts "   ⚠️  System degradation detected!"
        break
      end
    end

    puts "\n" + "="*80
    puts "STRESS TEST SUMMARY"
    puts "="*80

    optimal = results.max_by { |r| r[:throughput] }
    puts "\n🎯 Optimal Configuration:"
    puts "   Threads: #{optimal[:threads]}"
    puts "   Throughput: #{optimal[:throughput]} ops/sec"
    puts "   P95 Latency: #{optimal[:p95_latency]}ms"

    puts "\n📈 Results by Thread Count:"
    results.each do |r|
      status = r == optimal ? "✅ OPTIMAL" : ""
      puts "   #{r[:threads]} threads: #{r[:throughput]} ops/sec, P95: #{r[:p95_latency]}ms #{status}"
    end

    File.write('stress_test_results.json', JSON.pretty_generate(results))
    puts "\n💾 Results saved to stress_test_results.json"
  end

  desc "Run endurance test"
  task :endurance, [:duration_minutes] => :environment do |_t, args|
    duration_minutes = (args[:duration_minutes] || 10).to_i

    puts "\n" + "="*80
    puts "ENDURANCE TEST"
    puts "Duration: #{duration_minutes} minutes"
    puts "="*80 + "\n"

    setup_use_cases(['simple_loan'])

    metrics = {
      operations: [],
      errors: [],
      latencies: [],
      memory_samples: []
    }

    start_time = Time.now
    end_time = start_time + (duration_minutes * 60)
    sample_interval = 60 # 1 minute

    thread_count = 4
    threads = []

    # Monitoring thread
    monitor = Thread.new do
      while Time.now < end_time
        sleep sample_interval

        elapsed_minutes = ((Time.now - start_time) / 60).round(1)
        memory_mb = `ps -o rss= -p #{Process.pid}`.to_i / 1024

        metrics[:memory_samples] << {
          elapsed_minutes: elapsed_minutes,
          memory_mb: memory_mb
        }

        puts "[#{elapsed_minutes}m] Memory: #{memory_mb} MB"
      end
    end

    # Worker threads
    thread_count.times do
      threads << Thread.new do
        minute_ops = 0
        minute_start = Time.now

        while Time.now < end_time
          begin
            context = generate_random_loan_context
            op_start = Time.now
            SimpleLoanUseCase.evaluate(context)
            latency = (Time.now - op_start) * 1000
            minute_ops += 1

            # Record metrics every minute
            if Time.now - minute_start >= 60
              metrics[:operations] << minute_ops
              metrics[:latencies] << latency
              minute_ops = 0
              minute_start = Time.now
            end
          rescue => e
            metrics[:errors] << e.message
          end
        end
      end
    end

    threads.each(&:join)
    monitor.kill

    puts "\n" + "="*80
    puts "ENDURANCE TEST RESULTS"
    puts "="*80

    total_ops = metrics[:operations].sum
    avg_ops_per_minute = metrics[:operations].sum.to_f / metrics[:operations].length

    puts "\n📊 Performance:"
    puts "   Total operations: #{total_ops}"
    puts "   Avg ops/minute: #{avg_ops_per_minute.round(2)}"
    puts "   Total errors: #{metrics[:errors].length}"

    puts "\n💾 Memory:"
    if metrics[:memory_samples].any?
      initial_memory = metrics[:memory_samples].first[:memory_mb]
      final_memory = metrics[:memory_samples].last[:memory_mb]
      memory_growth = final_memory - initial_memory

      puts "   Initial: #{initial_memory} MB"
      puts "   Final: #{final_memory} MB"
      puts "   Growth: #{memory_growth} MB"
      puts "   Growth rate: #{(memory_growth.to_f / duration_minutes).round(2)} MB/min"

      if memory_growth > duration_minutes * 10 # More than 10MB per minute
        puts "   ⚠️  Potential memory leak detected!"
      else
        puts "   ✅ Memory usage stable"
      end
    end

    results = {
      duration_minutes: duration_minutes,
      total_operations: total_ops,
      errors: metrics[:errors].length,
      memory_samples: metrics[:memory_samples]
    }

    File.write('endurance_test_results.json', JSON.pretty_generate(results))
    puts "\n💾 Results saved to endurance_test_results.json"
  end

  # Helper methods
  def get_scenario_config(scenario)
    configs = {
      'light' => {
        operations_per_thread: 100,
        use_cases: ['simple_loan'],
        parallel_batching: false,
        warm_cache: false
      },
      'medium' => {
        operations_per_thread: 500,
        use_cases: ['simple_loan', 'fraud_detection', 'discount_engine'],
        parallel_batching: true,
        warm_cache: true
      },
      'heavy' => {
        operations_per_thread: 2000,
        use_cases: ['simple_loan', 'fraud_detection', 'discount_engine', 'insurance_underwriting', 'content_moderation'],
        parallel_batching: true,
        warm_cache: true
      },
      'burst' => {
        operations_per_thread: 10000,
        use_cases: ['simple_loan'],
        parallel_batching: true,
        warm_cache: true
      }
    }

    configs[scenario] || configs['medium']
  end

  def setup_use_cases(use_cases)
    use_cases.each do |use_case|
      case use_case
      when 'simple_loan'
        SimpleLoanUseCase.setup_rules
      when 'fraud_detection'
        FraudDetectionUseCase.setup_rules
      when 'discount_engine'
        DiscountEngineUseCase.setup_rules
      when 'insurance_underwriting'
        InsuranceUnderwritingUseCase.setup_rules
      when 'content_moderation'
        ContentModerationUseCase.setup_rules
      end
    end
  end

  def warm_cache(use_cases)
    use_cases.each do |use_case|
      case use_case
      when 'simple_loan'
        SimpleLoanUseCase.evaluate(generate_random_loan_context)
      when 'fraud_detection'
        FraudDetectionUseCase.evaluate(generate_random_fraud_context)
      when 'discount_engine'
        DiscountEngineUseCase.evaluate(generate_random_discount_context)
      when 'insurance_underwriting'
        InsuranceUnderwritingUseCase.evaluate(generate_random_insurance_context)
      when 'content_moderation'
        ContentModerationUseCase.evaluate(generate_random_content_context)
      end
    end
  end

  def run_thread_workload(thread_id, config, metrics, start_time, duration)
    operations = 0
    errors = 0
    end_time = start_time + duration

    while Time.now < end_time
      begin
        use_case = config[:use_cases].sample

        context = case use_case
        when 'simple_loan' then generate_random_loan_context
        when 'fraud_detection' then generate_random_fraud_context
        when 'discount_engine' then generate_random_discount_context
        when 'insurance_underwriting' then generate_random_insurance_context
        when 'content_moderation' then generate_random_content_context
        end

        op_start = Time.now

        result = case use_case
        when 'simple_loan' then SimpleLoanUseCase.evaluate(context)
        when 'fraud_detection' then FraudDetectionUseCase.evaluate(context)
        when 'discount_engine' then DiscountEngineUseCase.evaluate(context)
        when 'insurance_underwriting' then InsuranceUnderwritingUseCase.evaluate(context)
        when 'content_moderation' then ContentModerationUseCase.evaluate(context)
        end

        latency = (Time.now - op_start) * 1000
        metrics[:latencies] << latency
        metrics[:operations_completed].increment
        operations += 1
      rescue => e
        metrics[:errors].increment
        errors += 1
      end
    end

    { operations: operations, errors: errors }
  end

  def monitor_progress(metrics, start_time, duration)
    last_count = 0

    loop do
      sleep 5
      elapsed = Time.now - start_time
      current_count = metrics[:operations_completed].value
      ops_this_interval = current_count - last_count
      current_rate = (current_count / elapsed).round(2)

      remaining = duration - elapsed
      progress = (elapsed / duration * 100).round(1)

      print "\r⏳ Progress: #{progress}% | Operations: #{current_count} | Rate: #{current_rate} ops/sec | Remaining: #{remaining.round(0)}s "
      $stdout.flush

      last_count = current_count

      break if elapsed >= duration
    end
  end

  def percentile(sorted_array, percentile)
    return 0 if sorted_array.empty?
    k = (percentile / 100.0) * (sorted_array.length - 1)
    f = k.floor
    c = k.ceil

    if f == c
      sorted_array[k]
    else
      sorted_array[f] * (c - k) + sorted_array[c] * (k - f)
    end
  end

  def generate_random_loan_context
    {
      name: "Test User #{rand(1000)}",
      email: "test#{rand(1000)}@example.com",
      credit_score: rand(550..850),
      annual_income: rand(20000..150000),
      debt_to_income_ratio: rand(0.1..0.6).round(2)
    }
  end

  def generate_random_fraud_context
    {
      transaction_id: "TXN#{rand(100000)}",
      transaction_amount: rand(10..10000),
      device_fingerprint_match: [true, false].sample,
      location_match: [true, false].sample,
      ip_reputation_score: rand(0..100),
      transactions_last_hour: rand(0..10),
      distance_from_last_transaction_miles: rand(0..1000),
      time_since_last_transaction_minutes: rand(1..1440),
      merchant_age_days: rand(1..3650),
      is_international: [true, false].sample,
      transaction_hour: rand(0..23),
      merchant_category_mismatch: [true, false].sample
    }
  end

  def generate_random_discount_context
    {
      customer_id: "CUST#{rand(1000)}",
      customer_tier: %w[bronze silver gold platinum].sample,
      cart_total: rand(10..1000),
      total_items: rand(1..50),
      is_first_purchase: [true, false].sample,
      promo_code: [nil, 'WINTER2025', 'SUMMER2025'].sample
    }
  end

  def generate_random_insurance_context
    {
      name: "Driver #{rand(1000)}",
      email: "driver#{rand(1000)}@example.com",
      driver_age: rand(18..75),
      years_licensed: rand(1..50),
      accidents_3_years: rand(0..5),
      violations_3_years: rand(0..5),
      credit_score: rand(500..850),
      annual_mileage: rand(5000..30000),
      dui_history: [true, false].sample,
      license_suspended: false,
      sr22_required: false
    }
  end

  def generate_random_content_context
    {
      content_id: "CNT#{rand(100000)}",
      user_id: "USR#{rand(10000)}",
      toxicity_score: rand(0.0..1.0).round(2),
      profanity_count: rand(0..10),
      spam_likelihood: rand(0.0..1.0).round(2),
      sexual_content_score: rand(0.0..1.0).round(2),
      contains_hate_speech: false,
      contains_violence: false,
      contains_csam: false,
      threat_level: 'none',
      user_reputation_score: rand(0..100),
      user_account_age_days: rand(1..3650),
      user_reports_count: rand(0..5),
      external_links_count: rand(0..10),
      misinformation_indicators: rand(0..5),
      user_previous_violations_count: rand(0..10)
    }
  end
end
