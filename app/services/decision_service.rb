# Thread-safe Decision Service wrapper for DecisionAgent
# Demonstrates proper usage with versioning and caching
class DecisionService
  include Singleton

  def initialize
    @mutex = Mutex.new
    @cache = {}
    @cache_mutex = Mutex.new
    @agent_cache = {}
    @agent_cache_mutex = Mutex.new
  end

  # Create an agent from rules stored in database
  def create_agent(rule_id:, version: nil)
    rules_json = get_cached_rules(rule_id, version) do
      load_rules_from_db(rule_id, version)
    end

    return nil unless rules_json

    evaluator = DecisionAgent::Evaluators::JsonRuleEvaluator.new(
      rules_json: rules_json,
      name: "#{rule_id}_evaluator"
    )

    DecisionAgent::Agent.new(
      evaluators: [evaluator],
      scoring_strategy: DecisionAgent::Scoring::WeightedAverage.new,
      audit_adapter: DecisionAgent::Audit::NullAdapter.new
    )
  end

  # Evaluate rules with thread-safe caching
  # version can be either version_number (Integer) or version_id (Integer, database ID)
  def evaluate(rule_id:, context:, version: nil, version_id: nil)
    # If version_id is provided, convert it to version_number
    if version_id
      version_record = RuleVersion.find_by(id: version_id, rule_id: rule_id)
      version = version_record&.version_number if version_record
    end

    agent = get_cached_agent(rule_id, version)

    return { error: "Rule not found: #{rule_id}" } unless agent

    begin
      decision = agent.decide(context: context)

      {
        decision: decision.decision,
        confidence: decision.confidence,
        explanations: decision.explanations,
        evaluations: decision.evaluations.map(&:to_h),
        audit_payload: decision.audit_payload
      }
    rescue DecisionAgent::NoEvaluationsError
      { decision: nil, confidence: 0, explanations: ["No rules matched"] }
    rescue StandardError => e
      Rails.logger.error("Decision evaluation failed: #{e.message}")
      { error: e.message, rule_id: rule_id }
    end
  end

  # Bulk evaluation for multiple contexts (thread-safe)
  def evaluate_batch(rule_id:, contexts:, version: nil, parallel: false)
    if parallel && contexts.size > 1
      # Parallel processing with thread pool
      evaluate_parallel(rule_id, contexts, version)
    else
      # Sequential processing
      contexts.map { |ctx| evaluate(rule_id: rule_id, context: ctx, version: version) }
    end
  end

  # Save a new rule version
  def save_rule_version(rule_id:, content:, created_by: 'system', changelog: nil)
    @mutex.synchronize do
      rule = Rule.find_or_initialize_by(rule_id: rule_id)

      # Extract metadata from content
      if content.is_a?(Hash)
        rule.ruleset = content[:ruleset] || content['ruleset'] || rule_id
        rule.description = content[:description] || content['description'] || ''
        rule.status ||= 'active'
        rule.save!
      end

      # Create new version
      last_version = RuleVersion.where(rule_id: rule_id)
                               .order(version_number: :desc)
                               .first

      version_number = last_version ? last_version.version_number + 1 : 1

      version = RuleVersion.create!(
        rule_id: rule_id,
        version_number: version_number,
        content: content.to_json,
        created_by: created_by,
        changelog: changelog || "Version #{version_number}",
        status: 'draft'
      )

      # Invalidate cache
      invalidate_cache(rule_id)

      version
    end
  end

  # Activate a specific version
  def activate_version(version_id)
    @mutex.synchronize do
      version = RuleVersion.find(version_id)
      version.activate!
      invalidate_cache(version.rule_id)
      version
    end
  end

  # Get version history for a rule
  def version_history(rule_id, limit: 10)
    RuleVersion.where(rule_id: rule_id)
               .order(version_number: :desc)
               .limit(limit)
  end

  # Rollback to a previous version
  def rollback(rule_id:, version_number:)
    @mutex.synchronize do
      version = RuleVersion.find_by(rule_id: rule_id, version_number: version_number)
      return nil unless version

      version.activate!
      invalidate_cache(rule_id)
      version
    end
  end

  # Clear all caches
  def clear_cache
    @cache_mutex.synchronize do
      @cache.clear
    end
    @agent_cache_mutex.synchronize do
      @agent_cache.clear
    end
  end

  # Get version manager instance
  def version_manager
    @version_manager ||= DecisionAgent::Versioning::VersionManager.new(
      adapter: DecisionAgent::Versioning::ActiveRecordAdapter.new
    )
  end

  # Compare two versions
  def compare_versions(rule_id, version1, version2)
    version_manager.compare_versions(rule_id: rule_id, version1: version1, version2: version2)
  end

  private

  # Get or create cached agent instance
  def get_cached_agent(rule_id, version)
    cache_key = build_cache_key(rule_id, version)

    @agent_cache_mutex.synchronize do
      return @agent_cache[cache_key] if @agent_cache.key?(cache_key)

      agent = create_agent(rule_id: rule_id, version: version)
      @agent_cache[cache_key] = agent if agent
      agent
    end
  end

  def load_rules_from_db(rule_id, version)
    content = if version
      rule_version = RuleVersion.find_by(rule_id: rule_id, version_number: version)
      rule_version&.parsed_content
    else
      rule = Rule.find_by(rule_id: rule_id)
      rule&.active_version&.parsed_content
    end
    
    # Convert symbol keys to string keys for JsonRuleEvaluator compatibility
    content ? deep_stringify_keys(content) : nil
  end

  # Recursively convert symbol keys to string keys
  def deep_stringify_keys(obj)
    case obj
    when Hash
      obj.each_with_object({}) do |(key, value), result|
        string_key = key.is_a?(Symbol) ? key.to_s : key
        result[string_key] = deep_stringify_keys(value)
      end
    when Array
      obj.map { |item| deep_stringify_keys(item) }
    else
      obj
    end
  end

  def get_cached_rules(rule_id, version)
    cache_key = build_cache_key(rule_id, version)

    @cache_mutex.synchronize do
      return @cache[cache_key] if @cache.key?(cache_key)

      result = yield
      @cache[cache_key] = result if result
      result
    end
  end

  def build_cache_key(rule_id, version)
    version ? "#{rule_id}:v#{version}" : "#{rule_id}:active"
  end

  def invalidate_cache(rule_id)
    @cache_mutex.synchronize do
      @cache.delete_if { |key, _| key.start_with?("#{rule_id}:") }
    end
    @agent_cache_mutex.synchronize do
      @agent_cache.delete_if { |key, _| key.start_with?("#{rule_id}:") }
    end
  end

  def evaluate_parallel(rule_id, contexts, version)
    # Use a thread pool for parallel evaluation
    threads = contexts.map do |context|
      Thread.new do
        evaluate(rule_id: rule_id, context: context, version: version)
      end
    end

    threads.map(&:value)
  end
end
