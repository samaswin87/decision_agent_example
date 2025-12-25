namespace :performance do
  desc "Run comprehensive performance benchmarks"
  task benchmark: :environment do
    require 'benchmark'

    puts "\n" + "="*80
    puts "DECISION AGENT PERFORMANCE BENCHMARK SUITE"
    puts "="*80 + "\n"

    # Test configuration
    iterations = {
      single: 1000,
      batch_small: 100,
      batch_medium: 50,
      batch_large: 10
    }

    # Setup test data
    puts "\n📊 Setting up test data..."
    setup_test_rules

    results = {
      single_evaluation: {},
      batch_sequential: {},
      batch_parallel: {},
      cache_performance: {},
      version_operations: {},
      concurrent_stress: {}
    }

    # 1. Single Evaluation Performance
    puts "\n1️⃣  Single Evaluation Performance"
    puts "-" * 80

    test_context = {
      name: "Test User",
      email: "test@example.com",
      credit_score: 720,
      annual_income: 65000,
      debt_to_income_ratio: 0.35
    }

    time = Benchmark.measure do
      iterations[:single].times do
        SimpleLoanUseCase.evaluate(test_context)
      end
    end

    results[:single_evaluation] = {
      iterations: iterations[:single],
      total_time: time.real,
      avg_time_ms: (time.real / iterations[:single] * 1000).round(3),
      throughput_per_sec: (iterations[:single] / time.real).round(2)
    }

    puts "   Iterations: #{results[:single_evaluation][:iterations]}"
    puts "   Total time: #{results[:single_evaluation][:total_time].round(3)}s"
    puts "   Avg per evaluation: #{results[:single_evaluation][:avg_time_ms]}ms"
    puts "   Throughput: #{results[:single_evaluation][:throughput_per_sec]} evaluations/sec"

    # 2. Batch Sequential Performance
    puts "\n2️⃣  Batch Sequential Performance"
    puts "-" * 80

    batch_contexts = Array.new(100) { generate_random_loan_context }

    time = Benchmark.measure do
      iterations[:batch_small].times do
        DecisionService.instance.evaluate_batch(
          ['simple_loan_approval'],
          batch_contexts,
          parallel: false
        )
      end
    end

    results[:batch_sequential] = {
      batch_size: 100,
      iterations: iterations[:batch_small],
      total_time: time.real,
      avg_batch_time_ms: (time.real / iterations[:batch_small] * 1000).round(3),
      avg_per_item_ms: (time.real / (iterations[:batch_small] * 100) * 1000).round(3)
    }

    puts "   Batch size: #{results[:batch_sequential][:batch_size]}"
    puts "   Iterations: #{results[:batch_sequential][:iterations]}"
    puts "   Total time: #{results[:batch_sequential][:total_time].round(3)}s"
    puts "   Avg per batch: #{results[:batch_sequential][:avg_batch_time_ms]}ms"
    puts "   Avg per item: #{results[:batch_sequential][:avg_per_item_ms]}ms"

    # 3. Batch Parallel Performance
    puts "\n3️⃣  Batch Parallel Performance (Multi-threaded)"
    puts "-" * 80

    time = Benchmark.measure do
      iterations[:batch_small].times do
        DecisionService.instance.evaluate_batch(
          ['simple_loan_approval'],
          batch_contexts,
          parallel: true
        )
      end
    end

    results[:batch_parallel] = {
      batch_size: 100,
      iterations: iterations[:batch_small],
      total_time: time.real,
      avg_batch_time_ms: (time.real / iterations[:batch_small] * 1000).round(3),
      avg_per_item_ms: (time.real / (iterations[:batch_small] * 100) * 1000).round(3),
      speedup_vs_sequential: (results[:batch_sequential][:total_time] / time.real).round(2)
    }

    puts "   Batch size: #{results[:batch_parallel][:batch_size]}"
    puts "   Iterations: #{results[:batch_parallel][:iterations]}"
    puts "   Total time: #{results[:batch_parallel][:total_time].round(3)}s"
    puts "   Avg per batch: #{results[:batch_parallel][:avg_batch_time_ms]}ms"
    puts "   Avg per item: #{results[:batch_parallel][:avg_per_item_ms]}ms"
    puts "   🚀 Speedup: #{results[:batch_parallel][:speedup_vs_sequential]}x faster than sequential"

    # 4. Cache Performance
    puts "\n4️⃣  Cache Performance"
    puts "-" * 80

    # Clear cache
    DecisionService.instance.clear_cache

    # Cold cache
    time_cold = Benchmark.measure do
      iterations[:single].times do
        SimpleLoanUseCase.evaluate(test_context)
      end
    end

    # Warm cache
    time_warm = Benchmark.measure do
      iterations[:single].times do
        SimpleLoanUseCase.evaluate(test_context)
      end
    end

    results[:cache_performance] = {
      iterations: iterations[:single],
      cold_cache_time: time_cold.real,
      warm_cache_time: time_warm.real,
      cold_avg_ms: (time_cold.real / iterations[:single] * 1000).round(3),
      warm_avg_ms: (time_warm.real / iterations[:single] * 1000).round(3),
      cache_improvement: ((time_cold.real - time_warm.real) / time_cold.real * 100).round(2)
    }

    puts "   Cold cache avg: #{results[:cache_performance][:cold_avg_ms]}ms"
    puts "   Warm cache avg: #{results[:cache_performance][:warm_avg_ms]}ms"
    puts "   ⚡ Cache improvement: #{results[:cache_performance][:cache_improvement]}%"

    # 5. Version Operations Performance
    puts "\n5️⃣  Version Operations Performance"
    puts "-" * 80

    time_create = Benchmark.measure do
      50.times do |i|
        DecisionService.instance.save_rule_version(
          rule_id: "perf_test_rule",
          content: {conditions: {all: []}, decision: "test_v#{i}"}.to_json,
          created_by: "benchmark",
          changelog: "Benchmark version #{i}"
        )
      end
    end

    time_activate = Benchmark.measure do
      25.times do |i|
        DecisionService.instance.activate_version("perf_test_rule", i + 1)
      end
    end

    time_history = Benchmark.measure do
      100.times do
        DecisionService.instance.version_history("perf_test_rule")
      end
    end

    results[:version_operations] = {
      create_versions: 50,
      create_total_time: time_create.real,
      create_avg_ms: (time_create.real / 50 * 1000).round(3),
      activate_operations: 25,
      activate_total_time: time_activate.real,
      activate_avg_ms: (time_activate.real / 25 * 1000).round(3),
      history_queries: 100,
      history_total_time: time_history.real,
      history_avg_ms: (time_history.real / 100 * 1000).round(3)
    }

    puts "   Create version avg: #{results[:version_operations][:create_avg_ms]}ms"
    puts "   Activate version avg: #{results[:version_operations][:activate_avg_ms]}ms"
    puts "   Version history avg: #{results[:version_operations][:history_avg_ms]}ms"

    # 6. Concurrent Stress Test
    puts "\n6️⃣  Concurrent Stress Test (Multi-threaded)"
    puts "-" * 80

    thread_counts = [2, 4, 8, 16]
    concurrent_results = {}

    thread_counts.each do |thread_count|
      time = Benchmark.measure do
        threads = []
        thread_count.times do
          threads << Thread.new do
            100.times do
              SimpleLoanUseCase.evaluate(generate_random_loan_context)
            end
          end
        end
        threads.each(&:join)
      end

      total_operations = thread_count * 100
      concurrent_results[thread_count] = {
        total_time: time.real,
        throughput: (total_operations / time.real).round(2),
        avg_ms: (time.real / total_operations * 1000).round(3)
      }

      puts "   #{thread_count} threads: #{concurrent_results[thread_count][:throughput]} ops/sec (#{concurrent_results[thread_count][:avg_ms]}ms avg)"
    end

    results[:concurrent_stress] = concurrent_results

    # Summary Report
    puts "\n" + "="*80
    puts "PERFORMANCE SUMMARY"
    puts "="*80

    puts "\n📈 Key Metrics:"
    puts "   Single evaluation: #{results[:single_evaluation][:avg_time_ms]}ms"
    puts "   Batch parallel speedup: #{results[:batch_parallel][:speedup_vs_sequential]}x"
    puts "   Cache improvement: #{results[:cache_performance][:cache_improvement]}%"
    puts "   Max throughput: #{concurrent_results.values.map { |r| r[:throughput] }.max} ops/sec"

    puts "\n🎯 Recommendations:"
    if results[:batch_parallel][:speedup_vs_sequential] > 2.0
      puts "   ✅ Parallel processing is highly effective for batch operations"
    else
      puts "   ⚠️  Parallel processing shows limited improvement - consider workload characteristics"
    end

    if results[:cache_performance][:cache_improvement] > 50
      puts "   ✅ Caching is highly effective - ensure cache warming for production"
    end

    puts "\n💾 Saving results to performance_results.json..."
    File.write('performance_results.json', JSON.pretty_generate(results))
    puts "   ✅ Results saved!"

    puts "\n" + "="*80
    puts "Benchmark complete! 🎉"
    puts "="*80 + "\n"
  end

  desc "Run memory profiling"
  task memory_profile: :environment do
    require 'objspace'

    puts "\n" + "="*80
    puts "MEMORY PROFILING"
    puts "="*80 + "\n"

    setup_test_rules

    # Track memory before
    GC.start
    memory_before = `ps -o rss= -p #{Process.pid}`.to_i

    puts "Memory before: #{memory_before / 1024} MB"

    # Run operations
    contexts = Array.new(1000) { generate_random_loan_context }

    puts "\nEvaluating 1000 loan applications..."
    contexts.each do |context|
      SimpleLoanUseCase.evaluate(context)
    end

    # Track memory after
    GC.start
    memory_after = `ps -o rss= -p #{Process.pid}`.to_i

    puts "Memory after: #{memory_after / 1024} MB"
    puts "Memory increase: #{(memory_after - memory_before) / 1024} MB"
    puts "Per evaluation: #{((memory_after - memory_before) / 1000.0).round(2)} KB"

    # Object allocation stats
    total_objects = ObjectSpace.count_objects
    puts "\nObject counts:"
    puts "   Total: #{total_objects[:TOTAL]}"
    puts "   Free: #{total_objects[:FREE]}"
    puts "   Strings: #{total_objects[:T_STRING]}"
    puts "   Hashes: #{total_objects[:T_HASH]}"
    puts "   Arrays: #{total_objects[:T_ARRAY]}"
  end

  desc "Run comparison benchmark across all use cases"
  task compare_use_cases: :environment do
    puts "\n" + "="*80
    puts "USE CASE COMPARISON BENCHMARK"
    puts "="*80 + "\n"

    use_cases = [
      {
        name: "Simple Loan",
        setup: -> { SimpleLoanUseCase.setup_rules },
        evaluate: -> { SimpleLoanUseCase.evaluate(generate_random_loan_context) }
      },
      {
        name: "Fraud Detection",
        setup: -> { FraudDetectionUseCase.setup_rules },
        evaluate: -> { FraudDetectionUseCase.evaluate(generate_random_fraud_context) }
      },
      {
        name: "Discount Engine",
        setup: -> { DiscountEngineUseCase.setup_rules },
        evaluate: -> { DiscountEngineUseCase.evaluate(generate_random_discount_context) }
      },
      {
        name: "Insurance Underwriting",
        setup: -> { InsuranceUnderwritingUseCase.setup_rules },
        evaluate: -> { InsuranceUnderwritingUseCase.evaluate(generate_random_insurance_context) }
      },
      {
        name: "Content Moderation",
        setup: -> { ContentModerationUseCase.setup_rules },
        evaluate: -> { ContentModerationUseCase.evaluate(generate_random_content_context) }
      }
    ]

    results = {}

    use_cases.each do |use_case|
      puts "\n#{use_case[:name]}"
      puts "-" * 80

      # Setup
      use_case[:setup].call

      # Benchmark
      time = Benchmark.measure do
        1000.times { use_case[:evaluate].call }
      end

      results[use_case[:name]] = {
        total_time: time.real,
        avg_ms: (time.real / 1000 * 1000).round(3),
        throughput: (1000 / time.real).round(2)
      }

      puts "   Avg time: #{results[use_case[:name]][:avg_ms]}ms"
      puts "   Throughput: #{results[use_case[:name]][:throughput]} ops/sec"
    end

    puts "\n" + "="*80
    puts "COMPARISON SUMMARY"
    puts "="*80

    sorted = results.sort_by { |_, v| v[:avg_ms] }
    puts "\nRanking (fastest to slowest):"
    sorted.each_with_index do |(name, data), index|
      puts "   #{index + 1}. #{name}: #{data[:avg_ms]}ms"
    end
  end

  # Helper methods
  def setup_test_rules
    SimpleLoanUseCase.setup_rules
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
