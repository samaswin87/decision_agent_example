# Content Moderation Use Case
# Multi-layered content safety evaluation system
class ContentModerationUseCase
  class << self
    def setup_rules
      # Rule 1: Severe Violations - Immediate Block
      DecisionService.instance.save_rule_version(
        rule_id: 'content_severe_violations',
        content: {
          conditions: {
            any: [
              { fact: 'contains_hate_speech', operator: 'eq', value: true },
              { fact: 'contains_violence', operator: 'eq', value: true },
              { fact: 'contains_csam', operator: 'eq', value: true },
              { fact: 'toxicity_score', operator: 'gte', value: 0.9 },
              { fact: 'threat_level', operator: 'eq', value: 'critical' }
            ]
          },
          decision: 'block',
          priority: 200,
          metadata: {
            severity: 'critical',
            action: 'immediate_block',
            user_action: 'suspend_account',
            notify_authorities: true,
            appeal_allowed: false,
            retention_policy: 'evidence_preservation',
            review_required: false
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Critical content violations requiring immediate action'
      )
      DecisionService.instance.activate_version('content_severe_violations', 1)

      # Rule 2: High Risk - Human Review Required
      DecisionService.instance.save_rule_version(
        rule_id: 'content_high_risk',
        content: {
          conditions: {
            any: [
              {
                all: [
                  { fact: 'toxicity_score', operator: 'gte', value: 0.7 },
                  { fact: 'toxicity_score', operator: 'lt', value: 0.9 }
                ]
              },
              { fact: 'profanity_count', operator: 'gte', value: 5 },
              { fact: 'sexual_content_score', operator: 'gte', value: 0.75 },
              { fact: 'spam_likelihood', operator: 'gte', value: 0.8 },
              {
                all: [
                  { fact: 'user_reputation_score', operator: 'lt', value: 30 },
                  { fact: 'toxicity_score', operator: 'gte', value: 0.5 }
                ]
              }
            ]
          },
          decision: 'hold_for_review',
          priority: 150,
          metadata: {
            severity: 'high',
            action: 'quarantine',
            user_action: 'warn',
            notify_authorities: false,
            appeal_allowed: true,
            review_required: true,
            review_priority: 'high',
            max_review_time_hours: 4
          }
        }.to_json,
        created_by: 'system',
        changelog: 'High risk content requiring human moderation'
      )
      DecisionService.instance.activate_version('content_high_risk', 1)

      # Rule 3: Medium Risk - Automated Filter with Monitoring
      DecisionService.instance.save_rule_version(
        rule_id: 'content_medium_risk',
        content: {
          conditions: {
            any: [
              {
                all: [
                  { fact: 'toxicity_score', operator: 'gte', value: 0.4 },
                  { fact: 'toxicity_score', operator: 'lt', value: 0.7 }
                ]
              },
              {
                all: [
                  { fact: 'profanity_count', operator: 'gte', value: 2 },
                  { fact: 'profanity_count', operator: 'lt', value: 5 }
                ]
              },
              {
                all: [
                  { fact: 'spam_likelihood', operator: 'gte', value: 0.5 },
                  { fact: 'spam_likelihood', operator: 'lt', value: 0.8 }
                ]
              },
              { fact: 'misinformation_indicators', operator: 'gte', value: 2 }
            ]
          },
          decision: 'filter',
          priority: 100,
          metadata: {
            severity: 'medium',
            action: 'apply_filters',
            user_action: 'educate',
            filters: ['blur_content', 'reduce_reach', 'age_gate'],
            notify_authorities: false,
            appeal_allowed: true,
            review_required: false,
            monitoring_period_days: 30
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Medium risk content with automated filtering'
      )
      DecisionService.instance.activate_version('content_medium_risk', 1)

      # Rule 4: Low Risk - Monitor
      DecisionService.instance.save_rule_version(
        rule_id: 'content_low_risk',
        content: {
          conditions: {
            any: [
              {
                all: [
                  { fact: 'toxicity_score', operator: 'gte', value: 0.2 },
                  { fact: 'toxicity_score', operator: 'lt', value: 0.4 }
                ]
              },
              { fact: 'profanity_count', operator: 'eq', value: 1 },
              { fact: 'user_reports_count', operator: 'gte', value: 1 },
              {
                all: [
                  { fact: 'user_account_age_days', operator: 'lt', value: 7 },
                  { fact: 'external_links_count', operator: 'gte', value: 3 }
                ]
              }
            ]
          },
          decision: 'monitor',
          priority: 50,
          metadata: {
            severity: 'low',
            action: 'log_and_monitor',
            user_action: 'none',
            notify_authorities: false,
            appeal_allowed: false,
            review_required: false,
            monitoring_duration_hours: 72,
            flag_for_review_if_reported: true
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Low risk content for monitoring'
      )
      DecisionService.instance.activate_version('content_low_risk', 1)

      # Rule 5: Safe Content
      DecisionService.instance.save_rule_version(
        rule_id: 'content_safe',
        content: {
          conditions: {
            all: [
              { fact: 'toxicity_score', operator: 'lt', value: 0.2 },
              { fact: 'profanity_count', operator: 'eq', value: 0 },
              { fact: 'spam_likelihood', operator: 'lt', value: 0.3 }
            ]
          },
          decision: 'approve',
          priority: 10,
          metadata: {
            severity: 'none',
            action: 'publish',
            user_action: 'none',
            notify_authorities: false,
            appeal_allowed: false,
            review_required: false
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Safe content for immediate publication'
      )
      DecisionService.instance.activate_version('content_safe', 1)

      puts "✓ Content moderation rules created successfully"
    end

    def evaluate(context)
      rule_ids = [
        'content_severe_violations',
        'content_high_risk',
        'content_medium_risk',
        'content_low_risk',
        'content_safe'
      ]

      # Evaluate against the first matching rule (in priority order)
      result = nil
      rule_ids.each do |rule_id|
        temp_result = DecisionService.instance.evaluate(rule_id: rule_id, context: context)
        if temp_result && !temp_result[:error]
          result = temp_result
          break
        end
      end
      result ||= { decision: 'safe', metadata: {} }

      # Analyze violations
      violations = []
      violations << 'hate_speech' if context[:contains_hate_speech]
      violations << 'violence' if context[:contains_violence]
      violations << 'csam' if context[:contains_csam]
      violations << 'high_toxicity' if (context[:toxicity_score] || 0) >= 0.7
      violations << 'excessive_profanity' if (context[:profanity_count] || 0) >= 5
      violations << 'sexual_content' if (context[:sexual_content_score] || 0) >= 0.75
      violations << 'spam' if (context[:spam_likelihood] || 0) >= 0.5
      violations << 'misinformation' if (context[:misinformation_indicators] || 0) >= 2

      # Add detailed analysis
      result[:analysis] = {
        content_id: context[:content_id],
        user_id: context[:user_id],
        violations_detected: violations,
        risk_scores: {
          toxicity: context[:toxicity_score],
          spam: context[:spam_likelihood],
          sexual_content: context[:sexual_content_score]
        },
        user_context: {
          reputation: context[:user_reputation_score],
          account_age_days: context[:user_account_age_days],
          previous_violations: context[:user_previous_violations_count]
        }
      }

      result
    end

    def evaluate_batch(contents, parallel: false)
      setup_rules

      start_time = Time.current

      results = if parallel
        contents.map do |content|
          Thread.new { evaluate(content) }
        end.map(&:value)
      else
        contents.map { |content| evaluate(content) }
      end

      end_time = Time.current
      duration = end_time - start_time

      {
        results: results,
        performance: {
          total_evaluations: contents.size,
          duration_seconds: duration.round(3),
          average_per_evaluation_ms: ((duration / contents.size) * 1000).round(2),
          evaluations_per_second: (contents.size / duration).round(2),
          parallel: parallel,
          started_at: start_time,
          completed_at: end_time
        }
      }
    end
  end
end
