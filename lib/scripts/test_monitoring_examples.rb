#!/usr/bin/env ruby
# frozen_string_literal: true

# Quick test script to verify monitoring examples work
# Usage: ruby test_monitoring_examples.rb

require_relative '../../app/use_cases/monitoring_architecture_examples.rb'

puts "Testing Monitoring Architecture Examples..."
puts "=" * 80

examples = [
  {
    name: "Automatic Monitoring",
    class: MonitoringArchitectureExamples::AutomaticMonitoringExample,
    description: "Tests wrapper pattern for automatic metric collection"
  },
  {
    name: "Manual Monitoring",
    class: MonitoringArchitectureExamples::ManualMonitoringExample,
    description: "Tests explicit metric recording with custom metadata"
  },
  {
    name: "Observer Pattern",
    class: MonitoringArchitectureExamples::ObserverPatternExample,
    description: "Tests callback-based real-time notifications"
  },
  {
    name: "Alert Manager",
    class: MonitoringArchitectureExamples::AlertManagerExample,
    description: "Tests rule-based alerting system"
  },
  {
    name: "Prometheus Exporter",
    class: MonitoringArchitectureExamples::PrometheusExporterExample,
    description: "Tests Prometheus metrics export"
  },
  {
    name: "Time Series",
    class: MonitoringArchitectureExamples::TimeSeriesExample,
    description: "Tests bucketed time series data"
  },
  {
    name: "Memory Management",
    class: MonitoringArchitectureExamples::MemoryManagementExample,
    description: "Tests automatic metric cleanup"
  },
  {
    name: "Dashboard Server",
    class: MonitoringArchitectureExamples::DashboardServerExample,
    description: "Tests full monitoring stack simulation"
  }
]

results = []

examples.each_with_index do |example, index|
  puts "\n[#{index + 1}/#{examples.length}] Running: #{example[:name]}"
  puts "Description: #{example[:description]}"
  puts "-" * 80

  begin
    start_time = Time.now
    collector = example[:class].run
    duration = (Time.now - start_time).round(2)

    # Verify collector has metrics
    stats = collector.statistics
    success = stats.dig(:decisions, :total).to_i > 0

    results << {
      name: example[:name],
      success: success,
      duration: duration,
      decisions: stats.dig(:decisions, :total),
      errors: stats.dig(:errors, :total)
    }

    if success
      puts "\n✅ PASSED (#{duration}s)"
      puts "   Decisions: #{stats.dig(:decisions, :total)}"
      puts "   Errors: #{stats.dig(:errors, :total) || 0}"
    else
      puts "\n⚠️  WARNING: No metrics recorded"
    end

  rescue StandardError => e
    results << {
      name: example[:name],
      success: false,
      duration: 0,
      error: e.message
    }
    puts "\n❌ FAILED: #{e.message}"
    puts e.backtrace.first(3).join("\n")
  end

  # Small pause between tests
  sleep(0.5)
end

# Summary
puts "\n" + "=" * 80
puts "TEST SUMMARY"
puts "=" * 80

passed = results.count { |r| r[:success] }
failed = results.count { |r| !r[:success] }

results.each do |result|
  status = result[:success] ? "✅ PASS" : "❌ FAIL"
  puts "#{status} - #{result[:name]} (#{result[:duration]}s)"
  if result[:error]
    puts "         Error: #{result[:error]}"
  end
end

puts "\n" + "=" * 80
puts "Total: #{results.length} | Passed: #{passed} | Failed: #{failed}"
puts "=" * 80

if failed > 0
  puts "\n⚠️  Some tests failed. Check the output above for details."
  exit(1)
else
  puts "\n✅ All tests passed!"
  exit(0)
end
