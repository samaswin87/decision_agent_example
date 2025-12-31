# DecisionAgent Example Application

A comprehensive Rails application demonstrating the `decision_agent` gem (v0.1.4) with **thread-safety**, **versioning**, **A/B testing**, **persistent monitoring**, **real-world use cases**, **performance testing**, and an interactive **web UI**.

## 🚀 Features

### Core Capabilities
- **Thread-Safe Decision Service** - Singleton pattern with Mutex for concurrent evaluations
- **Rule Versioning** - Track changes, rollback, and compare versions
- **JSON-based Rules** - Using JsonRuleEvaluator with if/then syntax
- **Batch Processing** - Sequential and parallel evaluation modes
- **Built-in Caching** - Performance optimization with cache invalidation

### 🆕 NEW in v0.1.4
- **A/B Testing** - Compare rule versions with statistical significance analysis
- **Persistent Monitoring** - Database-backed metrics storage with historical analysis
- **Web UI Integration** - Mount DecisionAgent visual rule builder in Rails
- **Advanced Monitoring** - Real-time dashboards, Prometheus export, Grafana integration

### Web UI & Visualization
- **Interactive Demos** - Test all use cases through web interface
- **Performance Dashboard** - Real-time performance testing and metrics
- **Threading Visualization** - Live multi-threaded execution monitoring
- **Rule Browser** - Explore all rules and their version history

### Performance & Load Testing
- **Benchmark Suite** - Comprehensive performance measurements
- **Load Testing** - Configurable scenarios (light, medium, heavy, burst)
- **Stress Testing** - Find system breaking points
- **Endurance Testing** - Long-running stability tests

### Real-World Use Cases (9 Examples)
1. **Simple Loan Approval** - 4-tier credit evaluation
2. **Advanced Loan Approval** - Multi-tier with employment history
3. **Fraud Detection** - Real-time transaction risk assessment
4. **Discount Engine** - 5-rule promotional system
5. **Insurance Underwriting** - Auto insurance risk tiers
6. **Content Moderation** - Multi-layer safety system
7. **Dynamic Pricing** - Demand-based price optimization
8. **Recommendation Engine** - Personalized content suggestions
9. **Multi-Stage Workflow** - Complex 4-stage approval process

## 📦 Quick Start

```bash
# Install dependencies
bundle install

# Setup database
rails db:create
rails db:migrate
rails db:seed

# Start the server
rails server

# Visit http://localhost:3000
```

## 🌐 Web Interface

### 🧪 NEW: Comprehensive Test Center

Access all DecisionAgent features in one place! Visit `/demo/test_center` for:

- **All Use Cases Testing** - Test all 11 use cases with auto-generated data
- **Data Generation** - Generate unlimited test data for any use case
- **Batch Testing Suite** - Run parallel and sequential batch tests
- **Monitoring Examples** - Test 8 different monitoring architectures
- **Rule Management** - Version control, comparison, and audit trails
- **Advanced Features** - Scoring strategies, conflict resolution, decision replay
- **Quick Actions** - Seed data, reset database, export results

### Main Pages

| Page | URL | Description |
|------|-----|-------------|
| **Home** | `/` | Overview with navigation to all features |
| **🧪 Test Center** | `/demo/test_center` | Comprehensive testing suite for all features |
| **🧪 A/B Testing** | `/demo/ab_testing` | **NEW** Compare rule versions with statistical analysis |
| **💾 Persistent Monitoring** | `/demo/persistent_monitoring` | **NEW** Database-backed metrics and historical data |
| **Performance Dashboard** | `/demo/performance_dashboard` | Run performance tests with metrics |
| **Threading Visualization** | `/demo/threading_visualization` | Real-time thread monitoring |
| **All Use Cases** | `/demo/all_use_cases` | Explore all 9 use case examples |
| **Test All Use Cases** | `/demo/test_all_use_cases` | Automated testing of all use cases |
| **Data Generator** | `/demo/generate_test_data` | Generate test data for any use case |
| **Batch Testing** | `/demo/batch_testing` | Batch testing with performance metrics |
| **Monitoring Examples** | `/demo/monitoring_examples` | Test all monitoring architectures |
| **Rule Versioning** | `/demo/rule_versioning` | Create and manage rule versions |
| **Scoring Strategies** | `/demo/scoring_strategies` | Test different scoring strategies |
| **Loan Approval** | `/demo/loan_approval` | Interactive loan evaluation form |
| **Discount Engine** | `/demo/discount_engine` | Calculate order discounts |
| **Fraud Detection** | `/demo/fraud_detection` | Transaction risk assessment |
| **Custom Evaluator** | `/demo/custom_evaluate` | Test any rule with JSON input |
| **Rule Browser** | `/demo/rules` | Browse all rules and versions |

## 💻 Command-Line Tools

### Performance Benchmarks

```bash
# Comprehensive performance test suite
rake performance:benchmark

# Memory usage profiling
rake performance:memory_profile

# Compare all use cases
rake performance:compare_use_cases
```

Example output:
```
1️⃣  Single Evaluation Performance
   Iterations: 1000
   Total time: 0.523s
   Avg per evaluation: 0.523ms
   Throughput: 1912.05 evaluations/sec

3️⃣  Batch Parallel Performance (Multi-threaded)
   Batch size: 100
   Iterations: 100
   🚀 Speedup: 3.45x faster than sequential
```

### Load Testing

```bash
# Run configurable load test
rake load_test:run[scenario,duration,threads]

# Examples:
rake load_test:run[light,30,2]      # Light load: 30s, 2 threads
rake load_test:run[medium,60,4]     # Medium load: 60s, 4 threads
rake load_test:run[heavy,120,8]     # Heavy load: 120s, 8 threads
rake load_test:run[burst,60,16]     # Burst test: 60s, 16 threads

# Find system breaking point
rake load_test:stress_test

# Long-running stability test
rake load_test:endurance[10]        # 10 minutes
```

Example load test output:
```
⏳ Progress: 45.2% | Operations: 15234 | Rate: 338.5 ops/sec | Remaining: 33s

LOAD TEST RESULTS
==================
Total operations: 30240
Successful: 30240
Success rate: 100.0%
Throughput: 504.0 ops/sec

Latency Statistics (ms):
   P50 (Median): 1.85ms
   P95: 4.23ms
   P99: 8.91ms
```

## 🆕 New Features Guide

### A/B Testing

Test different rule versions and analyze which performs better using statistical significance:

```ruby
# Visit /demo/ab_testing in the web UI

# Features:
# - Create A/B tests with champion vs challenger versions
# - Configure traffic split (e.g., 90/10 or 50/50)
# - Run tests with automatic user assignment
# - View statistical analysis with confidence levels
# - Compare approval rates, confidence scores, decision distribution
# - Get recommendations based on test results
```

**Use Cases:**
- Test new fraud detection thresholds before full rollout
- Compare aggressive vs conservative loan approval rules
- Validate pricing strategy changes with real data
- Optimize discount engine rules for better conversion

### Persistent Monitoring

Store decision metrics in the database for long-term analysis:

```ruby
# Visit /demo/persistent_monitoring in the web UI

# Features:
# - Record decisions to database with full persistence
# - Query historical data across different time ranges
# - View database statistics (decisions, evaluations, performance)
# - Run custom queries (high confidence, recent success, errors)
# - Cleanup old metrics with configurable retention policies
# - Analyze decision distribution and patterns
```

**Advantages over Memory Storage:**
- ✅ Survives application restarts
- ✅ Unlimited retention period
- ✅ Complex queries with ActiveRecord
- ✅ Historical trend analysis
- ✅ Production-ready for high-volume environments

### Web UI Integration

Mount the DecisionAgent visual rule builder directly in your Rails app:

```ruby
# config/routes.rb
require 'decision_agent/web/server'

Rails.application.routes.draw do
  # Mount DecisionAgent Web UI
  mount DecisionAgent::Web::Server, at: '/decision_agent'
end

# With authentication:
authenticate :user, ->(user) { user.admin? } do
  mount DecisionAgent::Web::Server, at: '/decision_agent'
end
```

Then visit `http://localhost:3000/decision_agent` to access the visual rule builder.

### Advanced Monitoring & Analytics

Real-time monitoring with Prometheus and Grafana integration:

```ruby
# Initialize metrics collection with database storage
collector = DecisionAgent::Monitoring::MetricsCollector.new(storage: :auto)

# Start real-time dashboard
DecisionAgent::Monitoring::DashboardServer.start!(
  port: 4568,
  metrics_collector: collector
)

# Record decisions automatically
monitored_agent = DecisionAgent::Monitoring::MonitoredAgent.new(
  agent,
  metrics_collector: collector
)

result = monitored_agent.evaluate(context)
```

**Features:**
- Real-time dashboard with WebSocket updates
- Prometheus metrics export at `/metrics`
- Intelligent alerting with anomaly detection
- Pre-built Grafana dashboards
- Custom KPI tracking

## 📊 Usage Examples

### 1. Simple Loan Approval

```ruby
result = SimpleLoanUseCase.evaluate({
  name: 'John Doe',
  email: 'john@example.com',
  credit_score: 720,
  annual_income: 65000,
  debt_to_income_ratio: 0.35
})

# Result:
{
  applicant: { name: "John Doe", email: "john@example.com" },
  decision: "approved",
  confidence: 1.0,
  explanations: ["Decision: approved (confidence: 1.0)"],
  metadata: { tier: "standard", max_loan_amount: 250000 }
}
```

### 2. Fraud Detection

```ruby
result = FraudDetectionUseCase.evaluate({
  transaction_id: "TXN123",
  transaction_amount: 1500,
  device_fingerprint_match: false,
  location_match: true,
  ip_reputation_score: 45,
  transactions_last_hour: 3
})

# Result:
{
  decision: "review",
  confidence: 0.85,
  metadata: {
    risk_level: "medium",
    action: "manual_review",
    risk_factors: ["device_mismatch", "low_ip_reputation"]
  }
}
```

### 3. Batch Processing

```ruby
# Sequential processing
results = DecisionService.instance.evaluate_batch(
  ['simple_loan_approval'],
  contexts,
  parallel: false
)

# Parallel processing (faster)
results = DecisionService.instance.evaluate_batch(
  ['simple_loan_approval'],
  contexts,
  parallel: true
)
```

### 4. Rule Versioning

```ruby
service = DecisionService.instance

# Create a new version
version = service.save_rule_version(
  rule_id: 'simple_loan_approval',
  content: updated_rules_json,
  created_by: 'admin',
  changelog: 'Updated credit score requirement'
)

# Activate the new version
service.activate_version('simple_loan_approval', version.version_number)

# View version history
history = service.version_history('simple_loan_approval')

# Rollback to previous version
service.rollback('simple_loan_approval', 1)
```

## 🏗️ Architecture

```
app/
├── services/
│   └── decision_service.rb             # Thread-safe singleton service
├── use_cases/
│   ├── simple_loan_use_case.rb         # Simple loan approval
│   ├── loan_approval_use_case.rb       # Advanced loan approval
│   ├── fraud_detection_use_case.rb     # Fraud detection
│   ├── discount_engine_use_case.rb     # Discount calculations
│   ├── insurance_underwriting_use_case.rb  # Insurance risk
│   ├── content_moderation_use_case.rb  # Content safety
│   ├── dynamic_pricing_use_case.rb     # Price optimization
│   ├── recommendation_engine_use_case.rb   # Recommendations
│   └── multi_stage_workflow_use_case.rb    # Complex workflows
├── controllers/
│   └── demo_controller.rb              # Web UI + API endpoints
├── views/demo/
│   ├── index.html.erb                  # Home page
│   ├── performance_dashboard.html.erb  # Performance testing UI
│   ├── threading_visualization.html.erb    # Threading monitor
│   ├── all_use_cases.html.erb          # Use case explorer
│   └── ...                             # Other demo pages
└── models/
    ├── rule.rb                         # Rule model
    └── rule_version.rb                 # Version model

lib/tasks/
├── performance.rake                    # Performance benchmarks
└── load_test.rake                      # Load testing tools
```

## 📐 Rule Definition Format

Rules use JSON with `if/then` syntax:

```json
{
  "conditions": {
    "all": [
      { "fact": "credit_score", "operator": "gte", "value": 750 },
      { "fact": "annual_income", "operator": "gte", "value": 75000 }
    ]
  },
  "decision": "approved",
  "priority": 100,
  "metadata": {
    "tier": "premium",
    "max_loan_amount": 500000
  }
}
```

### Supported Operators

#### Basic Operators
- `eq` - Equal
- `neq` - Not equal
- `gte` - Greater than or equal
- `lte` - Less than or equal
- `lt` - Less than
- `gt` - Greater than
- `in` - Value is in array
- `present` - Field is present (not nil)
- `blank` - Field is blank or nil

#### String Operators (NEW!)
- `contains` - String contains substring (case-sensitive)
- `starts_with` - String starts with prefix
- `ends_with` - String ends with suffix
- `matches` - String matches regular expression pattern

#### Numeric Operators (NEW!)
- `between` - Value is between min and max (inclusive)
- `modulo` - Value modulo divisor equals remainder (useful for A/B testing)
- `sqrt` - Square root calculation
- `abs` - Absolute value
- `round` - Round to nearest integer
- `floor` - Floor (round down)
- `ceil` - Ceil (round up)
- `sin`, `cos`, `tan` - Trigonometric functions
- `exp`, `log` - Exponential and logarithmic functions
- `power` - Power calculation (base^exponent)
- `min`, `max` - Minimum/maximum from array

#### Collection Operators (NEW!)
- `contains_all` - Array contains all specified elements
- `contains_any` - Array contains any of the specified elements
- `intersects` - Arrays have common elements (set intersection)
- `subset_of` - Array is a subset of another array

#### Statistical Aggregations (NEW!)
- `sum` - Sum of numeric array elements
- `average` / `mean` - Average (mean) of numeric array
- `median` - Median value of numeric array
- `stddev` / `standard_deviation` - Standard deviation
- `variance` - Variance calculation
- `percentile` - Nth percentile of numeric array
- `count` - Count of array elements

#### Date/Time Operators (NEW!)
- `before_date` - Date is before specified date
- `after_date` - Date is after specified date
- `within_days` - Date is within N days from now
- `day_of_week` - Date falls on specified day (Monday, Tuesday, etc.)
- `duration_seconds`, `duration_minutes`, `duration_hours`, `duration_days` - Duration calculations
- `add_days`, `subtract_days`, `add_hours`, `subtract_hours` - Date arithmetic
- `hour_of_day`, `day_of_month`, `month`, `year`, `week_of_year` - Time component extraction
- `rate_per_second`, `rate_per_minute`, `rate_per_hour` - Rate calculations from timestamps
- `moving_average`, `moving_sum`, `moving_max`, `moving_min` - Moving window calculations

#### Geospatial Operators (NEW!)
- `within_radius` - Point is within radius of center (Haversine formula)
- `in_polygon` - Point is inside polygon (ray casting algorithm)

#### Financial Calculations (NEW!)
- `compound_interest` - Compound interest calculation
- `present_value` - Present value calculation
- `future_value` - Future value calculation
- `payment` - Loan payment (PMT) calculation

#### String Aggregations (NEW!)
- `join` - Join array of strings with separator
- `length` - Length of string or array

**See the [Advanced Operators Demo](/demo/advanced_operators) for interactive examples!**

### Operator Performance Best Practices

When choosing operators, consider performance implications:

1. **String Operations**: `contains`, `starts_with`, and `ends_with` are **faster** than `matches` (regex). Use regex only when pattern matching is necessary.

2. **Geospatial**: Prefer `within_radius` for **circular areas**, `in_polygon` for **irregular shapes**. Radius checks are faster for simple distance calculations.

3. **Collections**: Use `contains_any` instead of multiple `eq` conditions in an `any` block. It's more efficient and readable.

**Example - Optimized Collection Check:**
```json
// ❌ Less efficient
{
  "any": [
    { "field": "status", "op": "eq", "value": "urgent" },
    { "field": "status", "op": "eq", "value": "critical" },
    { "field": "status", "op": "eq", "value": "emergency" }
  ]
}

// ✅ More efficient
{
  "field": "status",
  "op": "contains_any",
  "value": ["urgent", "critical", "emergency"]
}
```

### Condition Types
- `all` - All conditions must match (AND)
- `any` - At least one condition must match (OR)

## 🧵 Thread Safety

The `DecisionService` is fully thread-safe:

1. **Singleton Pattern** - Single instance across the application
2. **Mutex Locks** - Thread-safe rule updates and cache operations
3. **Cache Management** - Thread-safe caching with invalidation
4. **Parallel Evaluation** - Thread pool for batch processing
5. **Pessimistic Locking** - Database-level concurrency control

```ruby
# Safe for concurrent use
threads = 10.times.map do |i|
  Thread.new do
    service = DecisionService.instance
    service.evaluate(['simple_loan_approval'], {credit_score: 700 + i})
  end
end

threads.each(&:join)  # No race conditions!
```

## 🧪 Testing

```bash
# Run all tests
rails test

# Run specific test file
rails test test/services/decision_service_test.rb

# Run advanced operators tests
rails test test/services/advanced_operators_test.rb

# Run use case tests
rails test test/use_cases/
```

Test coverage includes:
- Thread safety (10 threads × 100 operations)
- Batch processing (sequential and parallel)
- Rule versioning and rollback
- Cache behavior
- All 9 use cases with multiple scenarios

## 📈 Performance Metrics

### Typical Performance (on modern hardware)

| Test Type | Throughput | Avg Latency |
|-----------|------------|-------------|
| Single Evaluation | ~2000 ops/sec | < 1ms |
| Batch Sequential | ~1500 ops/sec | 0.7ms/item |
| Batch Parallel | ~5000 ops/sec | 0.2ms/item |
| Cached Evaluation | ~10000 ops/sec | < 0.1ms |

### Scalability

| Threads | Throughput | Notes |
|---------|------------|-------|
| 1 | 2000 ops/sec | Baseline |
| 2 | 3800 ops/sec | 1.9x |
| 4 | 7200 ops/sec | 3.6x |
| 8 | 12000 ops/sec | 6.0x |
| 16 | 15000 ops/sec | 7.5x (diminishing returns) |

## 🔍 Database Schema

### Rules Table
```ruby
create_table :rules do |t|
  t.string :rule_id,      null: false, index: {unique: true}
  t.string :ruleset
  t.text :description
  t.string :status,       default: 'active'
  t.timestamps
end
```

### Rule Versions Table
```ruby
create_table :rule_versions do |t|
  t.string :rule_id,       null: false
  t.integer :version_number, null: false
  t.text :content,         null: false  # JSON
  t.string :created_by
  t.text :changelog
  t.string :status,        default: 'draft'
  t.timestamps
end

add_index :rule_versions, [:rule_id, :version_number], unique: true
add_index :rule_versions, [:rule_id, :status]
```

## 🎯 Use Case Details

### 1. Insurance Underwriting
- 4 risk tiers: Preferred, Standard, High Risk, Uninsurable
- Premium calculation with surcharges
- Coverage limit determination
- Factors: driving history, credit, annual mileage

### 2. Content Moderation
- 5 severity levels: Critical, High, Medium, Low, Safe
- Automated filtering and human review escalation
- Toxicity scoring, profanity detection
- Actions: block, quarantine, filter, monitor, approve

### 3. Dynamic Pricing
- 5 pricing strategies: Surge, Premium, Standard, Promotional, Clearance
- Demand-based optimization
- Competitive analysis
- Customer segment adjustments

### 4. Recommendation Engine
- 5 personalization strategies
- Cold start handling for new users
- Re-engagement campaigns
- Contextual/seasonal recommendations

### 5. Multi-Stage Workflow
- 4-stage approval process
- Conditional routing based on amount and risk
- Multi-level authorization requirements
- Complete workflow simulation

## 💡 Best Practices

1. **Use Caching** - Enable for repeated evaluations with same context
2. **Batch Processing** - Use parallel mode for >10 evaluations
3. **Version Management** - Always add meaningful changelogs
4. **Testing** - Test rules thoroughly before activation
5. **Monitoring** - Use performance dashboard to track metrics

## 🚦 Getting Started Checklist

- [ ] Install dependencies (`bundle install`)
- [ ] Create database (`rails db:create`)
- [ ] Run migrations (`rails db:migrate`)
- [ ] Seed sample data (`rails db:seed`)
- [ ] Start server (`rails server`)
- [ ] Visit home page (http://localhost:3000)
- [ ] Try performance dashboard
- [ ] Run benchmark suite (`rake performance:benchmark`)
- [ ] Explore use cases
- [ ] Run load tests

## 📝 License

This example application is provided as-is for demonstration purposes.

## 🤝 Contributing

This is an example application. Feel free to use it as a template for your own decision agent implementations!

---

**Built with ❤️ using the decision_agent gem**
