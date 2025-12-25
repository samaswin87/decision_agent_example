Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Demo routes
  root "demo#index"

  get "demo/loan_approval", to: "demo#loan_approval"
  post "demo/loan_approval", to: "demo#loan_approval"

  get "demo/discount_engine", to: "demo#discount_engine"
  post "demo/discount_engine", to: "demo#discount_engine"

  get "demo/fraud_detection", to: "demo#fraud_detection"
  post "demo/fraud_detection", to: "demo#fraud_detection"

  get "demo/custom_evaluate", to: "demo#custom_evaluate"
  post "demo/custom_evaluate", to: "demo#custom_evaluate"

  get "demo/rules", to: "demo#rules"
  get "demo/rule_versions/:rule_id", to: "demo#rule_versions"

  # Performance and threading routes
  get "demo/performance_dashboard", to: "demo#performance_dashboard"
  get "demo/threading_visualization", to: "demo#threading_visualization"
  post "demo/run_threading_test", to: "demo#run_threading_test"
  post "demo/run_performance_test", to: "demo#run_performance_test"
  get "demo/all_use_cases", to: "demo#all_use_cases"

  # UI Dashboard Use Case routes
  get "demo/ui_onboarding", to: "demo#ui_onboarding"
  post "demo/ui_onboarding", to: "demo#ui_onboarding"
  post "demo/ui_batch_process", to: "demo#ui_batch_process"
  get "demo/ui_metrics", to: "demo#ui_metrics"

  # Monitoring & Observability routes
  get "demo/monitoring_dashboard", to: "demo#monitoring_dashboard"
  post "demo/monitoring_evaluate", to: "demo#monitoring_evaluate"
  get "demo/monitoring_benchmark", to: "demo#monitoring_benchmark"
  post "demo/monitoring_benchmark", to: "demo#monitoring_benchmark"
  get "demo/monitoring_load_test", to: "demo#monitoring_load_test"
  post "demo/monitoring_load_test", to: "demo#monitoring_load_test"
  get "demo/monitoring_metrics_stream", to: "demo#monitoring_metrics_stream"

  # Multi-Use Case Monitoring
  get "demo/monitoring_multi", to: "demo#monitoring_multi"
  post "demo/monitoring_multi_evaluate", to: "demo#monitoring_multi_evaluate"

  # Test Center - Comprehensive testing suite
  get "demo/test_center", to: "demo#test_center"

  # Test All Use Cases
  get "demo/test_all_use_cases", to: "demo#test_all_use_cases"
  post "demo/run_all_use_case_tests", to: "demo#run_all_use_case_tests"

  # Data Generation
  get "demo/generate_test_data", to: "demo#generate_test_data"
  post "demo/create_test_data", to: "demo#create_test_data"

  # Batch Testing
  get "demo/batch_testing", to: "demo#batch_testing"
  post "demo/run_batch_tests", to: "demo#run_batch_tests"

  # Monitoring Examples
  get "demo/monitoring_examples", to: "demo#monitoring_examples"
  get "demo/test_monitoring", to: "demo#test_monitoring"
  post "demo/run_monitoring_tests", to: "demo#run_monitoring_tests"

  # Rule Management
  get "demo/rule_versioning", to: "demo#rule_versioning"
  post "demo/create_rule_version", to: "demo#create_rule_version"
  post "demo/activate_rule_version", to: "demo#activate_rule_version"
  post "demo/rollback_rule", to: "demo#rollback_rule"

  get "demo/rule_comparison", to: "demo#rule_comparison"
  get "demo/compare_rule_versions", to: "demo#compare_rule_versions"

  get "demo/rule_audit", to: "demo#rule_audit"

  # Advanced Features
  get "demo/scoring_strategies", to: "demo#scoring_strategies"
  post "demo/test_scoring", to: "demo#test_scoring"

  get "demo/conflict_resolution", to: "demo#conflict_resolution"
  post "demo/test_conflict_resolution", to: "demo#test_conflict_resolution"

  get "demo/evaluator_comparison", to: "demo#evaluator_comparison"
  post "demo/compare_evaluators", to: "demo#compare_evaluators"

  get "demo/decision_replay", to: "demo#decision_replay"
  post "demo/replay_decision", to: "demo#replay_decision"

  # Quick Actions
  post "demo/seed_all_data", to: "demo#seed_all_data"
  post "demo/reset_database", to: "demo#reset_database"
  get "demo/run_all_tests", to: "demo#run_all_tests"
  get "demo/export_results", to: "demo#export_results"

  # NEW: A/B Testing
  get "demo/ab_testing", to: "demo#ab_testing"
  post "demo/create_ab_test", to: "demo#create_ab_test"
  post "demo/run_ab_test", to: "demo#run_ab_test"
  get "demo/ab_test_results/:test_id", to: "demo#ab_test_results"
  post "demo/complete_ab_test/:test_id", to: "demo#complete_ab_test"

  # NEW: Persistent Monitoring
  get "demo/persistent_monitoring", to: "demo#persistent_monitoring"
  post "demo/record_persistent_decisions", to: "demo#record_persistent_decisions"
  get "demo/database_stats", to: "demo#database_stats"
  get "demo/historical_data/:time_range", to: "demo#historical_data"
  post "demo/cleanup_metrics", to: "demo#cleanup_metrics"
  get "demo/custom_query/:query_type", to: "demo#custom_query"
end
