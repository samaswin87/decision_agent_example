# Service to manage A/B testing using DecisionAgent gem
class ABTestingService
  include Singleton

  def initialize
    @ab_test_manager = DecisionAgent::ABTesting::ABTestManager.new(
      storage_adapter: DecisionAgent::ABTesting::Storage::MemoryAdapter.new,
      version_manager: DecisionService.instance.version_manager
    )
  end

  attr_reader :ab_test_manager

  # Create a new A/B test
  def create_test(name:, champion_version_id:, challenger_version_id:, traffic_split: { champion: 90, challenger: 10 })
    ab_test_manager.create_test(
      name: name,
      champion_version_id: champion_version_id,
      challenger_version_id: challenger_version_id,
      traffic_split: traffic_split
    )
  end

  # Get all active tests
  def active_tests
    ab_test_manager.active_tests
  end

  # Get test by ID
  def get_test(test_id)
    ab_test_manager.get_test(test_id)
  end

  # Get test results
  def get_results(test_id)
    ab_test_manager.get_results(test_id)
  end

  # Start a test
  def start_test(test_id)
    ab_test_manager.start_test(test_id)
  end

  # Complete a test
  def complete_test(test_id)
    ab_test_manager.complete_test(test_id)
  end

  # Run an A/B test by assigning variants and recording decisions
  def run_test(test_id:, contexts:, rule_id:)
    test = get_test(test_id)
    return { error: "Test not found: #{test_id}" } unless test

    results = []
    assignments = []

    contexts.each_with_index do |context, index|
      user_id = context[:user_id] || "user_#{index}"
      
      # Assign variant
      assignment = ab_test_manager.assign_variant(test_id: test_id, user_id: user_id)
      assignments << assignment

      # Get version ID for the assigned variant
      version_id = assignment[:version_id]

      # Evaluate using the assigned version (version_id is the database ID)
      service = DecisionService.instance
      decision_result = service.evaluate(
        rule_id: rule_id,
        context: context,
        version_id: version_id
      )

      # Record decision result
      ab_test_manager.record_decision(
        assignment_id: assignment[:assignment_id],
        decision: decision_result[:decision],
        confidence: decision_result[:confidence] || 0.0
      )

      results << {
        user_id: user_id,
        variant: assignment[:variant],
        decision: decision_result[:decision],
        confidence: decision_result[:confidence]
      }
    end

    {
      test_id: test_id,
      processed: results.length,
      results: results,
      assignments: assignments
    }
  end

  # Get list of all tests
  def list_tests(status: nil)
    # Use reflection to access private storage_adapter
    storage_adapter = ab_test_manager.instance_variable_get(:@storage_adapter)
    storage_adapter.list_tests(status: status)
  end
end

