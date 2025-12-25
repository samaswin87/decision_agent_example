# Recommendation Engine Use Case
# Personalized content and product recommendations
class RecommendationEngineUseCase
  class << self
    def setup_rules
      # Rule 1: Highly Personalized Recommendations
      DecisionService.instance.save_rule_version(
        rule_id: 'recommendation_highly_personalized',
        content: {
          conditions: {
            all: [
              { fact: 'user_interaction_count', operator: 'gte', value: 50 },
              { fact: 'profile_completeness', operator: 'gte', value: 80 },
              { fact: 'days_since_last_visit', operator: 'lte', value: 3 }
            ]
          },
          decision: 'highly_personalized',
          priority: 200,
          metadata: {
            strategy: 'deep_personalization',
            algorithms: ['collaborative_filtering', 'content_based', 'deep_learning', 'session_based'],
            weight_distribution: {
              user_history: 40,
              similar_users: 25,
              trending: 10,
              content_match: 20,
              diversity: 5
            },
            recommendation_count: 20,
            diversity_factor: 0.3,
            novelty_factor: 0.4,
            engagement_prediction_threshold: 0.7,
            features: ['real_time_personalization', 'context_awareness', 'a_b_testing']
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Highly personalized recommendations for engaged users'
      )
      DecisionService.instance.activate_version('recommendation_highly_personalized', 1)

      # Rule 2: Personalized Recommendations
      DecisionService.instance.save_rule_version(
        rule_id: 'recommendation_personalized',
        content: {
          conditions: {
            all: [
              { fact: 'user_interaction_count', operator: 'gte', value: 10 },
              { fact: 'user_interaction_count', operator: 'lt', value: 50 },
              { fact: 'profile_completeness', operator: 'gte', value: 40 }
            ]
          },
          decision: 'personalized',
          priority: 150,
          metadata: {
            strategy: 'moderate_personalization',
            algorithms: ['collaborative_filtering', 'content_based', 'popularity'],
            weight_distribution: {
              user_history: 35,
              similar_users: 20,
              trending: 25,
              content_match: 15,
              diversity: 5
            },
            recommendation_count: 15,
            diversity_factor: 0.4,
            novelty_factor: 0.3,
            engagement_prediction_threshold: 0.5,
            features: ['category_based', 'trending_items']
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Personalized recommendations for regular users'
      )
      DecisionService.instance.activate_version('recommendation_personalized', 1)

      # Rule 3: Cold Start - New Users
      DecisionService.instance.save_rule_version(
        rule_id: 'recommendation_cold_start',
        content: {
          conditions: {
            any: [
              { fact: 'user_interaction_count', operator: 'lt', value: 10 },
              { fact: 'is_new_user', operator: 'eq', value: true }
            ]
          },
          decision: 'cold_start',
          priority: 100,
          metadata: {
            strategy: 'cold_start_onboarding',
            algorithms: ['popularity', 'trending', 'demographic'],
            weight_distribution: {
              user_history: 0,
              similar_users: 10,
              trending: 50,
              content_match: 25,
              diversity: 15
            },
            recommendation_count: 12,
            diversity_factor: 0.6,
            novelty_factor: 0.2,
            engagement_prediction_threshold: 0.3,
            features: ['onboarding_flow', 'preference_learning', 'category_exploration'],
            show_category_selector: true,
            collect_preferences: true
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Cold start recommendations for new users'
      )
      DecisionService.instance.activate_version('recommendation_cold_start', 1)

      # Rule 4: Re-engagement - Dormant Users
      DecisionService.instance.save_rule_version(
        rule_id: 'recommendation_reengagement',
        content: {
          conditions: {
            all: [
              { fact: 'days_since_last_visit', operator: 'gte', value: 30 },
              { fact: 'user_interaction_count', operator: 'gte', value: 10 }
            ]
          },
          decision: 're_engagement',
          priority: 180,
          metadata: {
            strategy: 're_engagement_campaign',
            algorithms: ['user_history', 'trending', 'comeback_special'],
            weight_distribution: {
              user_history: 30,
              similar_users: 10,
              trending: 40,
              content_match: 10,
              diversity: 10
            },
            recommendation_count: 10,
            diversity_factor: 0.5,
            novelty_factor: 0.6,
            engagement_prediction_threshold: 0.4,
            features: ['whats_new', 'comeback_offers', 'personalized_email'],
            show_whats_new: true,
            special_offers: true,
            highlight_changes: true
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Re-engagement recommendations for dormant users'
      )
      DecisionService.instance.activate_version('recommendation_reengagement', 1)

      # Rule 5: Contextual - Special Occasions
      DecisionService.instance.save_rule_version(
        rule_id: 'recommendation_contextual',
        content: {
          conditions: {
            any: [
              { fact: 'is_holiday_season', operator: 'eq', value: true },
              { fact: 'is_user_birthday_month', operator: 'eq', value: true },
              { fact: 'special_event_active', operator: 'eq', value: true }
            ]
          },
          decision: 'contextual_special',
          priority: 190,
          metadata: {
            strategy: 'event_based_personalization',
            algorithms: ['event_specific', 'user_history', 'trending'],
            weight_distribution: {
              user_history: 20,
              similar_users: 15,
              trending: 30,
              content_match: 15,
              diversity: 10,
              event_specific: 10
            },
            recommendation_count: 15,
            diversity_factor: 0.4,
            novelty_factor: 0.5,
            engagement_prediction_threshold: 0.6,
            features: ['seasonal_content', 'gift_recommendations', 'limited_time_offers'],
            show_event_banner: true,
            gift_mode_enabled: true
          }
        }.to_json,
        created_by: 'system',
        changelog: 'Contextual recommendations for special occasions'
      )
      DecisionService.instance.activate_version('recommendation_contextual', 1)

      puts "✓ Recommendation engine rules created successfully"
    end

    def evaluate(context)
      rule_ids = [
        'recommendation_contextual',
        'recommendation_highly_personalized',
        'recommendation_reengagement',
        'recommendation_personalized',
        'recommendation_cold_start'
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
      result ||= { decision: 'cold_start', metadata: {} }

      metadata = result[:metadata] || {}

      # Generate recommendation details
      recommendation_count = metadata['recommendation_count'] || 10
      algorithms = metadata['algorithms'] || ['popularity']

      result[:recommendation_config] = {
        user_id: context[:user_id],
        strategy: metadata['strategy'],
        algorithms_used: algorithms,
        count: recommendation_count,
        diversity_factor: metadata['diversity_factor'],
        novelty_factor: metadata['novelty_factor'],
        weight_distribution: metadata['weight_distribution']
      }

      # User profile insights
      result[:user_profile] = {
        interaction_count: context[:user_interaction_count],
        profile_completeness: "#{context[:profile_completeness]}%",
        days_since_last_visit: context[:days_since_last_visit],
        is_new_user: context[:is_new_user],
        engagement_level: calculate_engagement_level(context)
      }

      # Feature flags
      result[:features] = {
        enabled: metadata['features'] || [],
        show_category_selector: metadata['show_category_selector'] || false,
        show_whats_new: metadata['show_whats_new'] || false,
        special_offers: metadata['special_offers'] || false,
        gift_mode: metadata['gift_mode_enabled'] || false
      }

      # Predicted engagement
      result[:predictions] = {
        engagement_threshold: metadata['engagement_prediction_threshold'],
        expected_click_through_rate: calculate_expected_ctr(context, metadata),
        expected_conversion_rate: calculate_expected_conversion(context, metadata)
      }

      result
    end

    def evaluate_batch(user_contexts, parallel: false)
      contexts = user_contexts.map do |user|
        {
          user_id: user[:user_id],
          user_interaction_count: user[:user_interaction_count],
          profile_completeness: user[:profile_completeness],
          days_since_last_visit: user[:days_since_last_visit],
          is_new_user: user[:is_new_user],
          is_holiday_season: user[:is_holiday_season],
          is_user_birthday_month: user[:is_user_birthday_month],
          special_event_active: user[:special_event_active]
        }
      end

      rule_ids = [
        'recommendation_contextual',
        'recommendation_highly_personalized',
        'recommendation_reengagement',
        'recommendation_personalized',
        'recommendation_cold_start'
      ]

      DecisionService.instance.evaluate_batch(rule_ids, contexts, parallel: parallel)
    end

    private

    def calculate_engagement_level(context)
      interactions = context[:user_interaction_count] || 0
      days_active = [1, 365 - (context[:days_since_last_visit] || 365)].max

      engagement_score = (interactions.to_f / days_active) * 100

      if engagement_score >= 5
        'highly_engaged'
      elsif engagement_score >= 1
        'moderately_engaged'
      elsif engagement_score >= 0.1
        'lightly_engaged'
      else
        'dormant'
      end
    end

    def calculate_expected_ctr(context, metadata)
      base_ctr = 0.05 # 5% baseline

      # Adjust based on engagement
      interactions = context[:user_interaction_count] || 0
      engagement_boost = [interactions / 100.0 * 0.02, 0.10].min

      # Adjust based on personalization level
      personalization_boost = case metadata['strategy']
      when 'deep_personalization' then 0.15
      when 'moderate_personalization' then 0.08
      when 'cold_start_onboarding' then 0.03
      when 're_engagement_campaign' then 0.06
      when 'event_based_personalization' then 0.12
      else 0.0
      end

      ((base_ctr + engagement_boost + personalization_boost) * 100).round(2)
    end

    def calculate_expected_conversion(context, metadata)
      base_conversion = 0.01 # 1% baseline

      # Profile completeness impact
      completeness = (context[:profile_completeness] || 0) / 100.0
      completeness_boost = completeness * 0.02

      # Strategy impact
      strategy_boost = case metadata['strategy']
      when 'deep_personalization' then 0.04
      when 'moderate_personalization' then 0.02
      when 're_engagement_campaign' then 0.015
      when 'event_based_personalization' then 0.03
      else 0.005
      end

      ((base_conversion + completeness_boost + strategy_boost) * 100).round(2)
    end
  end
end
