# Service to manage persistent monitoring using DecisionAgent gem
class PersistentMonitoringService
  include Singleton

  def initialize
    # Auto-detect storage: uses database if models are available, else memory
    @metrics_collector = DecisionAgent::Monitoring::MetricsCollector.new(storage: :auto)
  end

  attr_reader :metrics_collector

  # Record a decision with context
  def record_decision(decision_result, context, duration_ms: nil)
    # Create a mock decision object if needed
    decision = create_decision_object(decision_result)
    
    duration_ms ||= calculate_duration(decision_result)
    
    metrics_collector.record_decision(
      decision: decision,
      context: context,
      duration_ms: duration_ms
    )
  end

  # Get statistics for a time range
  def statistics(time_range: 3600)
    metrics_collector.statistics(time_range: time_range)
  end

  # Get database stats if using ActiveRecord storage
  def database_stats
    if using_database_storage?
      {
        total_decisions: decision_log_count,
        total_evaluations: evaluation_metric_count,
        total_performance: performance_metric_count,
        total_errors: error_metric_count,
        success_rate: calculate_success_rate,
        avg_confidence: calculate_avg_confidence,
        avg_duration: calculate_avg_duration,
        p95_latency: calculate_p95_latency
      }
    else
      {
        message: "Using in-memory storage. Run 'rails generate decision_agent:install --monitoring' to enable database storage."
      }
    end
  rescue => e
    Rails.logger.error("Error getting database stats: #{e.message}")
    { error: e.message }
  end

  # Cleanup old metrics
  def cleanup_metrics(older_than: 30.days.to_i)
    if using_database_storage?
      metrics_collector.cleanup_old_metrics_from_storage(older_than: older_than)
      { success: true, message: "Cleaned up metrics older than #{older_than} seconds" }
    else
      { message: "Using in-memory storage. No cleanup needed." }
    end
  rescue => e
    Rails.logger.error("Error cleaning up metrics: #{e.message}")
    { error: e.message }
  end

  # Get historical data for a time range
  def historical_data(time_range: 3600)
    stats = statistics(time_range: time_range)
    
    # Extract decision distribution
    decisions = if using_database_storage?
      get_decision_distribution(time_range)
    else
      # From in-memory stats
      stats[:decisions] || {}
    end

    {
      time_range: time_range,
      decisions: decisions,
      total: decisions.values.sum,
      statistics: stats
    }
  end

  private

  def using_database_storage?
    # Check if ActiveRecord models are available
    defined?(DecisionLog) && DecisionLog.respond_to?(:count)
  rescue
    false
  end

  def decision_log_count
    DecisionLog.count
  rescue
    0
  end

  def evaluation_metric_count
    EvaluationMetric.count
  rescue
    0
  end

  def performance_metric_count
    PerformanceMetric.count
  rescue
    0
  end

  def error_metric_count
    ErrorMetric.count
  rescue
    0
  end

  def calculate_success_rate
    total = DecisionLog.count
    return 0.0 if total == 0
    
    successful = DecisionLog.where(status: 'success').count
    (successful.to_f / total).round(3)
  rescue
    0.0
  end

  def calculate_avg_confidence
    DecisionLog.where.not(confidence: nil).average(:confidence)&.to_f&.round(3) || 0.0
  rescue
    0.0
  end

  def calculate_avg_duration
    PerformanceMetric.average(:duration_ms)&.to_f&.round(2) || 0.0
  rescue
    0.0
  end

  def calculate_p95_latency
    # Simple approximation - in production you'd use percentile calculation
    avg = calculate_avg_duration
    (avg * 1.5).round(2) # Rough P95 approximation
  rescue
    0.0
  end

  def get_decision_distribution(time_range)
    start_time = Time.now - time_range
    DecisionLog.where('created_at >= ?', start_time)
               .group(:decision)
               .count
  rescue
    {}
  end

  def create_decision_object(decision_result)
    # Create a mock Decision object that has the required interface
    decision_result = decision_result.with_indifferent_access if decision_result.is_a?(Hash)
    
    OpenStruct.new(
      decision: decision_result[:decision] || decision_result['decision'],
      confidence: decision_result[:confidence] || decision_result['confidence'] || 0.0,
      evaluations: decision_result[:evaluations] || decision_result['evaluations'] || []
    )
  end

  def calculate_duration(decision_result)
    # Extract duration from result if available, otherwise use a default
    if decision_result.is_a?(Hash)
      decision_result[:duration_ms] || decision_result['duration_ms'] || 10.0
    else
      10.0
    end
  end
end

