require 'test_helper'

class DecisionServiceTest < ActiveSupport::TestCase
  setup do
    @service = DecisionService.instance
    @service.clear_cache

    # Create test rule
    @test_rule = Rule.create!(
      rule_id: 'test_rule_001',
      ruleset: 'test',
      description: 'Test rule',
      status: 'active'
    )

    @rule_content = {
      rule_id: 'test_rule_001',
      name: 'Age Verification Rule',
      description: 'Checks if user is over 18',
      conditions: [
        {
          all: [
            { fact: 'age', operator: 'greaterThanInclusive', value: 18 }
          ]
        }
      ],
      event: {
        type: 'age_verified',
        params: {
          status: 'approved',
          message: 'User is of legal age'
        }
      }
    }

    @service.save_rule_version(
      rule_id: 'test_rule_001',
      content: @rule_content,
      created_by: 'test_system',
      changelog: 'Initial test version'
    )
    @test_rule.rule_versions.first.activate!
  end

  teardown do
    @service.clear_cache
  end

  test "singleton instance returns same object" do
    instance1 = DecisionService.instance
    instance2 = DecisionService.instance
    assert_same instance1, instance2
  end

  test "evaluate returns correct result for matching condition" do
    result = @service.evaluate(
      rule_id: 'test_rule_001',
      context: { age: 21 }
    )

    assert_equal 'age_verified', result.dig(:event, :type)
    assert_equal 'approved', result.dig(:event, :params, :status)
  end

  test "evaluate returns nil event for non-matching condition" do
    result = @service.evaluate(
      rule_id: 'test_rule_001',
      context: { age: 16 }
    )

    assert_nil result[:event]
  end

  test "evaluate caches rule content" do
    # First evaluation
    @service.evaluate(rule_id: 'test_rule_001', context: { age: 21 })

    # This should use cache (we can't directly test cache hit, but we verify no errors)
    result = @service.evaluate(rule_id: 'test_rule_001', context: { age: 25 })
    assert_equal 'age_verified', result.dig(:event, :type)
  end

  test "evaluate batch processes multiple contexts sequentially" do
    contexts = [
      { age: 21 },
      { age: 16 },
      { age: 30 }
    ]

    results = @service.evaluate_batch(
      rule_id: 'test_rule_001',
      contexts: contexts,
      parallel: false
    )

    assert_equal 3, results.length
    assert_equal 'age_verified', results[0].dig(:event, :type)
    assert_nil results[1][:event]
    assert_equal 'age_verified', results[2].dig(:event, :type)
  end

  test "evaluate batch processes multiple contexts in parallel" do
    contexts = [
      { age: 21 },
      { age: 25 },
      { age: 30 }
    ]

    results = @service.evaluate_batch(
      rule_id: 'test_rule_001',
      contexts: contexts,
      parallel: true
    )

    assert_equal 3, results.length
    results.each do |result|
      assert_equal 'age_verified', result.dig(:event, :type)
    end
  end

  test "save_rule_version creates new version" do
    new_content = @rule_content.merge(
      conditions: [
        { all: [{ fact: 'age', operator: 'greaterThanInclusive', value: 21 }] }
      ]
    )

    version = @service.save_rule_version(
      rule_id: 'test_rule_001',
      content: new_content,
      created_by: 'admin',
      changelog: 'Updated age requirement to 21'
    )

    assert_equal 2, version.version_number
    assert_equal 'Updated age requirement to 21', version.changelog
    assert_equal 'admin', version.created_by
  end

  test "save_rule_version invalidates cache" do
    # Cache the rule
    @service.evaluate(rule_id: 'test_rule_001', context: { age: 21 })

    # Update the rule
    new_content = @rule_content.merge(
      event: {
        type: 'age_verified_updated',
        params: { status: 'updated' }
      }
    )

    @service.save_rule_version(
      rule_id: 'test_rule_001',
      content: new_content,
      created_by: 'admin'
    )
    @test_rule.rule_versions.last.activate!

    # Verify cache was invalidated by checking new content is used
    result = @service.evaluate(rule_id: 'test_rule_001', context: { age: 21 })
    assert_equal 'age_verified_updated', result.dig(:event, :type)
  end

  test "activate_version changes active version" do
    # Create second version
    new_content = @rule_content.merge(
      event: { type: 'new_version', params: {} }
    )

    version2 = @service.save_rule_version(
      rule_id: 'test_rule_001',
      content: new_content,
      created_by: 'admin'
    )

    @service.activate_version(version2.id)

    result = @service.evaluate(rule_id: 'test_rule_001', context: { age: 21 })
    assert_equal 'new_version', result.dig(:event, :type)
  end

  test "compare_versions returns differences" do
    # Create second version
    new_content = @rule_content.merge(
      description: 'Updated description'
    )

    version2 = @service.save_rule_version(
      rule_id: 'test_rule_001',
      content: new_content,
      created_by: 'admin'
    )

    comparison = @service.compare_versions(
      @test_rule.rule_versions.first.id,
      version2.id
    )

    assert comparison[:differences].present?
  end

  test "version_history returns limited versions" do
    # Create multiple versions
    3.times do |i|
      @service.save_rule_version(
        rule_id: 'test_rule_001',
        content: @rule_content,
        created_by: 'admin',
        changelog: "Version #{i + 2}"
      )
    end

    history = @service.version_history('test_rule_001', limit: 2)
    assert_equal 2, history.length
  end

  test "rollback activates previous version" do
    # Create version 2
    @service.save_rule_version(
      rule_id: 'test_rule_001',
      content: @rule_content.merge(event: { type: 'v2', params: {} }),
      created_by: 'admin'
    )
    @test_rule.rule_versions.last.activate!

    # Create version 3
    @service.save_rule_version(
      rule_id: 'test_rule_001',
      content: @rule_content.merge(event: { type: 'v3', params: {} }),
      created_by: 'admin'
    )
    @test_rule.rule_versions.last.activate!

    # Rollback to version 2
    @service.rollback(rule_id: 'test_rule_001', version_number: 2)

    result = @service.evaluate(rule_id: 'test_rule_001', context: { age: 21 })
    assert_equal 'v2', result.dig(:event, :type)
  end

  test "validate_rule accepts valid syntax" do
    valid_rule = {
      rule_id: 'valid_rule',
      conditions: [{ all: [{ fact: 'x', operator: 'equal', value: 1 }] }],
      event: { type: 'test', params: {} }
    }

    result = @service.validate_rule(valid_rule)
    assert result[:valid]
  end

  test "thread safety with concurrent evaluations" do
    threads = 10.times.map do |i|
      Thread.new do
        100.times do
          @service.evaluate(
            rule_id: 'test_rule_001',
            context: { age: 18 + i }
          )
        end
      end
    end

    # Should complete without errors
    assert_nothing_raised do
      threads.each(&:join)
    end
  end

  test "thread safety with concurrent cache operations" do
    threads = 5.times.map do
      Thread.new do
        50.times do
          @service.evaluate(rule_id: 'test_rule_001', context: { age: 21 })
          @service.clear_cache if rand < 0.1
        end
      end
    end

    assert_nothing_raised do
      threads.each(&:join)
    end
  end

  test "handles non-existent rule gracefully" do
    result = @service.evaluate(
      rule_id: 'non_existent_rule',
      context: { age: 21 }
    )

    assert result[:error].present?
    assert_match /not found/, result[:error]
  end
end
