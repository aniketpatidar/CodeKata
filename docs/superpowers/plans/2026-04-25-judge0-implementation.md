# Judge0 Code Evaluation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the Judge0 integration for code evaluation, add dueling functionality, AI hints, and home dashboard to replace eval() with secure external code execution.

**Architecture:** Judge0Service wraps the Judge0 API for test execution. GeminiService provides AI hints using the ruby_llm gem. Duel model manages competitive coding challenges between users. AppSetting provides runtime feature toggles. All services integrate with existing controllers and ActionCable for real-time updates.

**Tech Stack:** Judge0 API (RapidAPI), Google Gemini API, ruby_llm gem, ActionCable for real-time broadcasts, Rails enums for Duel status

---

## File Structure Overview

**New files to create:**
- `/app/services/judge0_service.rb` — Judge0 API wrapper for code test execution
- `/app/services/gemini_service.rb` — Gemini API wrapper for AI hints
- `/app/models/duel.rb` — Duel model with relationships and state machine
- `/app/models/challenge_completion.rb` — Track solved challenges per user
- `/app/models/app_setting.rb` — Store feature toggles (ai_hints_enabled)
- `/db/migrate/*_create_duels.rb` — Duels table migration
- `/db/migrate/*_create_challenge_completions.rb` — Challenge completions table migration
- `/db/migrate/*_create_app_settings.rb` — App settings table migration
- `/app/views/duels/new.html.erb` — Duel creation form
- `/app/views/duels/show.html.erb` — Active duel view with live updates
- `/app/views/home/index.html.erb` — Dashboard with duels and progress

**Files to modify:**
- `/app/models/challenge.rb` — Add associations to duels and completions
- `/app/models/user.rb` — Add duel and challenge_completion associations
- `/app/controllers/code_evaluations_controller.rb` — Fix method_name reference
- `/config/routes.rb` — Add duel, hint, home, admin routes
- `/app/controllers/admin/base_controller.rb` — Ensure auth is correct
- `/db/migrate/*_change_tests_column_type_in_challenges.rb` — Verify method_template field (may already exist)

---

## Task 1: Create Services Directory and Judge0Service

**Files:**
- Create: `/app/services/judge0_service.rb`
- Create: `/test/services/judge0_service_test.rb`

- [ ] **Step 1: Create services directory**

```bash
mkdir -p /home/dev08/work/CodeKata/app/services
```

- [ ] **Step 2: Write failing test for Judge0Service**

```ruby
# test/services/judge0_service_test.rb
require "test_helper"

class Judge0ServiceTest < ActiveSupport::TestCase
  def setup
    @service = Judge0Service.new
  end

  test "run_tests returns hash with test results" do
    code = "def add(a, b)\n  a + b\nend"
    tests = [
      { input: "add(2, 3)", expected_output: "5" },
      { input: "add(0, 0)", expected_output: "0" }
    ]
    
    results = @service.run_tests(code, tests, "add")
    
    assert_kind_of Hash, results
    assert_equal 2, results.size
    assert results.values.all? { |r| r.is_a?(Hash) && r.has_key?(:passed) }
  end

  test "run_tests marks test as passed when output matches" do
    code = "def greet\n  'hello'\nend"
    tests = [{ input: "greet()", expected_output: "hello" }]
    
    results = @service.run_tests(code, tests, "greet")
    
    assert results.values.first[:passed], "Test should pass when output matches"
  end

  test "run_tests marks test as failed when output doesn't match" do
    code = "def add(a, b)\n  a - b\nend"
    tests = [{ input: "add(5, 3)", expected_output: "8" }]
    
    results = @service.run_tests(code, tests, "add")
    
    assert_not results.values.first[:passed], "Test should fail when output doesn't match"
  end

  test "run_tests raises KeyError when JUDGE0_API_KEY is missing" do
    service = Judge0Service.new
    allow(service).to receive(:judge0_api_key).and_return(nil)
    
    assert_raises KeyError do
      service.run_tests("code", [], "method")
    end
  end
end
```

- [ ] **Step 3: Implement Judge0Service**

```ruby
# app/services/judge0_service.rb
require "net/http"
require "json"

class Judge0Service
  BASE_URL = "https://judge0-ce.p.rapidapi.com"
  LANGUAGE_ID = 71  # Ruby language ID in Judge0
  
  def run_tests(code, tests, method_name)
    api_key = judge0_api_key
    raise KeyError, "JUDGE0_API_KEY is not set" if api_key.nil?

    results = {}
    
    tests.each_with_index do |test, idx|
      result = execute_test(code, test, method_name, api_key)
      results["test_#{idx}"] = result
    end
    
    results
  end

  private

  def judge0_api_key
    ENV["JUDGE0_API_KEY"]
  end

  def execute_test(code, test, method_name, api_key)
    # Wrap the user code with test execution
    wrapped_code = wrap_code_with_test(code, test, method_name)
    
    # Submit to Judge0
    submission_id = submit_to_judge0(wrapped_code, api_key)
    
    # Poll for result
    result = poll_judge0_result(submission_id, api_key)
    
    # Parse and return
    parse_judge0_result(result, test)
  end

  def wrap_code_with_test(code, test, method_name)
    <<~RUBY
      #{code}
      
      result = eval("#{test[:input]}")
      puts result.to_s
    RUBY
  end

  def submit_to_judge0(code, api_key)
    uri = URI("#{BASE_URL}/submissions?wait=false")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request["x-rapidapi-host"] = "judge0-ce.p.rapidapi.com"
    request["x-rapidapi-key"] = api_key
    
    request.body = JSON.generate({
      source_code: code,
      language_id: LANGUAGE_ID,
      stdin: ""
    })
    
    response = http.request(request)
    JSON.parse(response.body)["id"]
  rescue => e
    Rails.logger.error("Judge0 submission failed: #{e.message}")
    nil
  end

  def poll_judge0_result(submission_id, api_key)
    uri = URI("#{BASE_URL}/submissions/#{submission_id}")
    max_attempts = 30
    attempt = 0
    
    loop do
      attempt += 1
      break if attempt > max_attempts
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(uri.request_uri)
      request["x-rapidapi-host"] = "judge0-ce.p.rapidapi.com"
      request["x-rapidapi-key"] = api_key
      
      response = http.request(request)
      result = JSON.parse(response.body)
      
      return result if result["status"]["id"] > 2  # Completed or error
      
      sleep(0.5)
    end
    
    nil
  rescue => e
    Rails.logger.error("Judge0 result polling failed: #{e.message}")
    nil
  end

  def parse_judge0_result(judge0_result, test)
    return { passed: false, output: "", error: "No response from Judge0" } if judge0_result.nil?

    output = judge0_result["stdout"].to_s.strip
    expected = test[:expected_output].to_s.strip
    
    {
      passed: output == expected,
      output: output,
      expected: expected,
      error: judge0_result["stderr"]
    }
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /home/dev08/work/CodeKata
rails test test/services/judge0_service_test.rb
```

Expected: All tests pass (may need to mock HTTP calls in actual test)

- [ ] **Step 5: Commit**

```bash
cd /home/dev08/work/CodeKata
git add app/services/judge0_service.rb test/services/judge0_service_test.rb
git commit -m "feat: add Judge0Service for code evaluation"
```

---

## Task 2: Create GeminiService for AI Hints

**Files:**
- Create: `/app/services/gemini_service.rb`
- Create: `/test/services/gemini_service_test.rb`

- [ ] **Step 1: Write failing test for GeminiService**

```ruby
# test/services/gemini_service_test.rb
require "test_helper"

class GeminiServiceTest < ActiveSupport::TestCase
  def setup
    @service = GeminiService.new
  end

  test "hint returns a string hint for challenge and code" do
    challenge_desc = "Write a function that adds two numbers"
    code = "def add(a, b)\n  # your code here\nend"
    
    hint = @service.hint(challenge_desc, code)
    
    assert_kind_of String, hint
    assert hint.length > 0
  end

  test "hint includes relevant guidance" do
    challenge_desc = "Reverse a string"
    code = "def reverse_string(s)\n  \nend"
    
    hint = @service.hint(challenge_desc, code)
    
    assert hint.downcase.include?("string"), "Hint should relate to the challenge"
  end
end
```

- [ ] **Step 2: Implement GeminiService**

```ruby
# app/services/gemini_service.rb
class GeminiService
  def hint(challenge_description, user_code)
    client = RubyLLM::Client.new(api_key: gemini_api_key)
    
    prompt = <<~PROMPT
      A coding student is working on this challenge:
      #{challenge_description}
      
      Their current code:
      ```ruby
      #{user_code}
      ```
      
      Provide a brief, helpful hint (2-3 sentences) to guide them without giving away the solution.
      Focus on what they should think about or try next.
    PROMPT
    
    response = client.chat(
      model: "gemini-2.0-flash",
      messages: [{ role: "user", content: prompt }]
    )
    
    response.content
  rescue RubyLLM::AuthenticationError
    raise RubyLLM::AuthenticationError, "GEMINI_API_KEY is not configured or invalid"
  end

  private

  def gemini_api_key
    ENV["GEMINI_API_KEY"]
  end
end
```

- [ ] **Step 3: Run test to verify it passes**

```bash
cd /home/dev08/work/CodeKata
rails test test/services/gemini_service_test.rb
```

Expected: Tests pass or marked as skipped if API key not configured

- [ ] **Step 4: Commit**

```bash
cd /home/dev08/work/CodeKata
git add app/services/gemini_service.rb test/services/gemini_service_test.rb
git commit -m "feat: add GeminiService for AI-powered hints"
```

---

## Task 3: Create Duel Model and Migration

**Files:**
- Create: `/app/models/duel.rb`
- Create: `/db/migrate/*_create_duels.rb`
- Create: `/test/models/duel_test.rb`
- Modify: `/app/models/user.rb`
- Modify: `/app/models/challenge.rb`

- [ ] **Step 1: Create Duel migration**

```bash
cd /home/dev08/work/CodeKata
rails generate migration CreateDuels challenger:references opponent:references challenge:references winner:references status:integer started_at:datetime completed_at:datetime
```

- [ ] **Step 2: Edit migration to fix references and add proper columns**

```ruby
# db/migrate/[timestamp]_create_duels.rb
class CreateDuels < ActiveRecord::Migration[7.1]
  def change
    create_table :duels do |t|
      t.references :challenger, foreign_key: { to_table: :users }
      t.references :opponent, foreign_key: { to_table: :users }
      t.references :challenge, foreign_key: true
      t.references :winner, foreign_key: { to_table: :users }, null: true
      t.integer :status, default: 0
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
    
    add_index :duels, [:challenger_id, :opponent_id, :status]
  end
end
```

- [ ] **Step 3: Implement Duel model**

```ruby
# app/models/duel.rb
class Duel < ApplicationRecord
  belongs_to :challenger, class_name: "User"
  belongs_to :opponent, class_name: "User"
  belongs_to :challenge
  belongs_to :winner, class_name: "User", optional: true

  enum status: { pending: 0, active: 1, completed: 2 }

  validates :challenger_id, :opponent_id, :challenge_id, presence: true
  validate :challenger_cannot_be_opponent

  def participant?(user)
    challenger_id == user.id || opponent_id == user.id
  end

  def opponent_of(user)
    challenger_id == user.id ? opponent : challenger
  end

  def active?
    status == "active"
  end

  private

  def challenger_cannot_be_opponent
    if challenger_id == opponent_id
      errors.add(:opponent_id, "cannot duel themselves")
    end
  end
end
```

- [ ] **Step 4: Update User model to add duel associations**

Find the line `has_many :discussions, dependent: :destroy` in `/app/models/user.rb` and add after it:

```ruby
has_many :challenge_completions, dependent: :destroy
has_many :duels_as_challenger, class_name: "Duel", foreign_key: "challenger_id", dependent: :destroy
has_many :duels_as_opponent, class_name: "Duel", foreign_key: "opponent_id", dependent: :destroy
```

- [ ] **Step 5: Update Challenge model to add duel association**

Add to `/app/models/challenge.rb` after the enum line:

```ruby
has_many :duels, dependent: :destroy
has_many :challenge_completions, dependent: :destroy
```

- [ ] **Step 6: Write test for Duel model**

```ruby
# test/models/duel_test.rb
require "test_helper"

class DuelTest < ActiveSupport::TestCase
  def setup
    @user1 = users(:one)
    @user2 = users(:two)
    @challenge = challenges(:one)
  end

  test "duel requires challenger, opponent, and challenge" do
    duel = Duel.new(status: 0)
    assert_not duel.valid?
    assert duel.errors.include?(:challenger_id)
    assert duel.errors.include?(:opponent_id)
    assert duel.errors.include?(:challenge_id)
  end

  test "duel cannot be between same user" do
    duel = Duel.new(
      challenger: @user1,
      opponent: @user1,
      challenge: @challenge
    )
    assert_not duel.valid?
    assert duel.errors.include?(:opponent_id)
  end

  test "participant? returns true for challenger and opponent" do
    duel = Duel.create!(
      challenger: @user1,
      opponent: @user2,
      challenge: @challenge
    )
    assert duel.participant?(@user1)
    assert duel.participant?(@user2)
  end

  test "opponent_of returns correct opponent" do
    duel = Duel.create!(
      challenger: @user1,
      opponent: @user2,
      challenge: @challenge
    )
    assert_equal @user2, duel.opponent_of(@user1)
    assert_equal @user1, duel.opponent_of(@user2)
  end
end
```

- [ ] **Step 7: Run tests**

```bash
cd /home/dev08/work/CodeKata
rails test test/models/duel_test.rb
```

Expected: All tests pass

- [ ] **Step 8: Run migration**

```bash
cd /home/dev08/work/CodeKata
rails db:migrate
```

- [ ] **Step 9: Commit**

```bash
cd /home/dev08/work/CodeKata
git add app/models/duel.rb app/models/user.rb app/models/challenge.rb db/migrate/*_create_duels.rb test/models/duel_test.rb
git commit -m "feat: add Duel model with user and challenge relationships"
```

---

## Task 4: Create ChallengeCompletion Model and Migration

**Files:**
- Create: `/app/models/challenge_completion.rb`
- Create: `/db/migrate/*_create_challenge_completions.rb`

- [ ] **Step 1: Create ChallengeCompletion migration**

```bash
cd /home/dev08/work/CodeKata
rails generate migration CreateChallengeCompletions user:references challenge:references completed_at:datetime
```

- [ ] **Step 2: Edit migration**

```ruby
# db/migrate/[timestamp]_create_challenge_completions.rb
class CreateChallengeCompletions < ActiveRecord::Migration[7.1]
  def change
    create_table :challenge_completions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :challenge, null: false, foreign_key: true
      t.datetime :completed_at

      t.timestamps
    end
    
    add_index :challenge_completions, [:user_id, :challenge_id], unique: true
  end
end
```

- [ ] **Step 3: Implement ChallengeCompletion model**

```ruby
# app/models/challenge_completion.rb
class ChallengeCompletion < ApplicationRecord
  belongs_to :user
  belongs_to :challenge

  validates :user_id, :challenge_id, presence: true
  validates :user_id, uniqueness: { scope: :challenge_id }

  def self.find_or_create_by(user:, challenge:)
    where(user: user, challenge: challenge).first_or_create
  end
end
```

- [ ] **Step 4: Run migration**

```bash
cd /home/dev08/work/CodeKata
rails db:migrate
```

- [ ] **Step 5: Commit**

```bash
cd /home/dev08/work/CodeKata
git add app/models/challenge_completion.rb db/migrate/*_create_challenge_completions.rb
git commit -m "feat: add ChallengeCompletion to track solved challenges"
```

---

## Task 5: Create AppSetting Model and Migration

**Files:**
- Create: `/app/models/app_setting.rb`
- Create: `/db/migrate/*_create_app_settings.rb`

- [ ] **Step 1: Create AppSetting migration**

```bash
cd /home/dev08/work/CodeKata
rails generate migration CreateAppSettings key:string value:boolean
```

- [ ] **Step 2: Edit migration**

```ruby
# db/migrate/[timestamp]_create_app_settings.rb
class CreateAppSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :app_settings do |t|
      t.string :key, null: false
      t.boolean :value, default: false

      t.timestamps
    end
    
    add_index :app_settings, :key, unique: true
  end
end
```

- [ ] **Step 3: Implement AppSetting model**

```ruby
# app/models/app_setting.rb
class AppSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.ai_hints_enabled?
    find_by(key: "ai_hints_enabled")&.value || false
  end

  def self.enable_ai_hints!
    find_or_create_by(key: "ai_hints_enabled").update(value: true)
  end

  def self.disable_ai_hints!
    find_or_create_by(key: "ai_hints_enabled").update(value: false)
  end
end
```

- [ ] **Step 4: Run migration**

```bash
cd /home/dev08/work/CodeKata
rails db:migrate
```

- [ ] **Step 5: Commit**

```bash
cd /home/dev08/work/CodeKata
git add app/models/app_setting.rb db/migrate/*_create_app_settings.rb
git commit -m "feat: add AppSetting for feature toggles"
```

---

## Task 6: Fix CodeEvaluationsController Schema Issue

**Files:**
- Modify: `/app/controllers/code_evaluations_controller.rb`

- [ ] **Step 1: Check what's in challenge schema**

```bash
cd /home/dev08/work/CodeKata
rails dbconsole -p
```

Run: `\d challenges` or `SELECT column_name FROM information_schema.columns WHERE table_name='challenges';`

Expected: You should see `method_template` and `tests` columns

- [ ] **Step 2: Update CodeEvaluationsController to fix method reference**

In `/app/controllers/code_evaluations_controller.rb` line 7, change:

```ruby
# FROM:
results = Judge0Service.new.run_tests(params[:code], challenge.tests, challenge.method_name)

# TO:
tests = JSON.parse(challenge.tests) if challenge.tests.is_a?(String)
tests ||= challenge.tests || []
results = Judge0Service.new.run_tests(params[:code], tests, challenge.method_template)
```

- [ ] **Step 3: Run existing tests to ensure controller still works**

```bash
cd /home/dev08/work/CodeKata
rails test test/controllers/code_evaluations_controller_test.rb
```

Expected: Tests pass

- [ ] **Step 4: Commit**

```bash
cd /home/dev08/work/CodeKata
git add app/controllers/code_evaluations_controller.rb
git commit -m "fix: use correct challenge column references (method_template, tests)"
```

---

## Task 7: Add Routes

**Files:**
- Modify: `/config/routes.rb`

- [ ] **Step 1: Check current routes**

```bash
cd /home/dev08/work/CodeKata
grep -n "duels\|hints\|home\|admin" config/routes.rb
```

- [ ] **Step 2: Add missing routes**

Find the line `post 'evaluate_code'` and add after it:

```ruby
# Home dashboard
get 'home', to: 'home#index', as: 'home'
root 'home#index'

# Duels
resources :duels, only: [:new, :create, :show] do
  member do
    patch :accept
  end
end

# AI Hints
post 'hints', to: 'hints#create'

# Admin namespace
namespace :admin do
  get 'settings', to: 'settings#show', as: 'settings'
  post 'settings', to: 'settings#update'
end
```

- [ ] **Step 3: Verify routes**

```bash
cd /home/dev08/work/CodeKata
rails routes | grep -E "duel|hint|home|admin"
```

Expected output should show all new routes

- [ ] **Step 4: Commit**

```bash
cd /home/dev08/work/CodeKata
git add config/routes.rb
git commit -m "feat: add routes for duels, hints, home, and admin settings"
```

---

## Task 8: Create Duel Views

**Files:**
- Create: `/app/views/duels/new.html.erb`
- Create: `/app/views/duels/show.html.erb`

- [ ] **Step 1: Create duels view directory**

```bash
mkdir -p /home/dev08/work/CodeKata/app/views/duels
```

- [ ] **Step 2: Create new duel form view**

```erb
<!-- app/views/duels/new.html.erb -->
<div class="container mx-auto px-4 py-8">
  <div class="max-w-2xl mx-auto">
    <h1 class="text-3xl font-bold mb-6">Challenge <%= @opponent.full_name %></h1>
    
    <form action="<%= duels_path %>" method="POST">
      <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
      <%= hidden_field_tag :opponent_id, @opponent.id %>
      
      <div class="mb-6">
        <label class="block text-lg font-semibold mb-3">Select a Challenge</label>
        <div class="space-y-2">
          <% @challenges.group_by(&:difficulty).each do |difficulty, challenges| %>
            <div class="mb-4">
              <h3 class="font-semibold text-gray-700 mb-2"><%= difficulty.titleize %></h3>
              <% challenges.each do |challenge| %>
                <label class="flex items-center p-3 border rounded hover:bg-gray-50">
                  <input type="radio" name="challenge_id" value="<%= challenge.id %>" required class="mr-3">
                  <span><%= challenge.name %></span>
                </label>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
      
      <div class="flex gap-3">
        <button type="submit" class="px-6 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
          Send Duel Challenge
        </button>
        <%= link_to "Cancel", home_path, class: "px-6 py-2 border rounded hover:bg-gray-50" %>
      </div>
    </form>
  </div>
</div>
```

- [ ] **Step 3: Create duel show view with live updates**

```erb
<!-- app/views/duels/show.html.erb -->
<div class="container mx-auto px-4 py-8">
  <div class="max-w-4xl mx-auto">
    <h1 class="text-2xl font-bold mb-6">
      <%= @duel.challenger.full_name %> vs <%= @duel.opponent.full_name %>
    </h1>
    
    <div class="grid grid-cols-2 gap-6 mb-6">
      <div class="border rounded p-4">
        <h2 class="font-semibold mb-2"><%= @duel.challenger.full_name %></h2>
        <p class="text-gray-600">Status: <span id="challenger-status" class="font-semibold"><%= @duel.status.humanize %></span></p>
        <p id="challenger-progress" class="mt-2">Tests: <span class="font-semibold">0 / <%= @duel.challenge.tests.size rescue 0 %></span></p>
      </div>
      
      <div class="border rounded p-4">
        <h2 class="font-semibold mb-2"><%= @duel.opponent.full_name %></h2>
        <p class="text-gray-600">Status: <span id="opponent-status" class="font-semibold"><%= @duel.status.humanize %></span></p>
        <p id="opponent-progress" class="mt-2">Tests: <span class="font-semibold">0 / <%= @duel.challenge.tests.size rescue 0 %></span></p>
      </div>
    </div>
    
    <div class="bg-gray-50 border rounded p-6 mb-6">
      <h3 class="text-lg font-semibold mb-2"><%= @duel.challenge.name %></h3>
      <p class="text-gray-700"><%= @duel.challenge.description %></p>
    </div>
    
    <% if @duel.pending? && @duel.opponent == current_user %>
      <form action="<%= duel_path(@duel) %>" method="POST">
        <input type="hidden" name="_method" value="PATCH">
        <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
        <button type="submit" class="px-6 py-2 bg-green-600 text-white rounded hover:bg-green-700">
          Accept Challenge
        </button>
      </form>
    <% elsif @duel.completed? %>
      <div class="bg-blue-50 border border-blue-200 rounded p-4">
        <p class="font-semibold">
          <% if @duel.winner_id == current_user.id %>
            🎉 You won! Congratulations!
          <% else %>
            <%= @duel.winner.full_name %> won this duel.
          <% end %>
        </p>
      </div>
    <% end %>
    
    <%= link_to "Back to Home", home_path, class: "mt-6 inline-block text-blue-600 hover:underline" %>
  </div>
</div>

<script>
  if ("<%= @duel.status %>" === "active" || "<%= @duel.status %>" === "pending") {
    const duelsChannel = App.cable.subscriptions.create(
      { channel: "DuelChannel", duel_id: <%= @duel.id %> },
      {
        received(data) {
          if (data.type === "progress") {
            if (data.user_id === <%= current_user.id %>) {
              document.getElementById("challenger-progress").innerHTML = 
                `Tests: <span class="font-semibold">${data.passed} / ${data.total}</span>`;
            } else {
              document.getElementById("opponent-progress").innerHTML = 
                `Tests: <span class="font-semibold">${data.passed} / ${data.total}</span>`;
            }
          } else if (data.type === "duel_won") {
            window.location.reload();
          } else if (data.type === "duel_started") {
            document.getElementById("challenger-status").textContent = "Active";
            document.getElementById("opponent-status").textContent = "Active";
          }
        }
      }
    );
  }
</script>
```

- [ ] **Step 4: Commit**

```bash
cd /home/dev08/work/CodeKata
git add app/views/duels/
git commit -m "feat: add duel views (new challenge and active duel)"
```

---

## Task 9: Create Home Dashboard View

**Files:**
- Create: `/app/views/home/index.html.erb`

- [ ] **Step 1: Create home view directory**

```bash
mkdir -p /home/dev08/work/CodeKata/app/views/home
```

- [ ] **Step 2: Create home dashboard view**

```erb
<!-- app/views/home/index.html.erb -->
<div class="container mx-auto px-4 py-8">
  <h1 class="text-4xl font-bold mb-8">CodeKata Dashboard</h1>
  
  <% if @new_user %>
    <div class="bg-blue-50 border border-blue-200 rounded p-6 mb-8">
      <h2 class="text-xl font-semibold mb-2">Welcome to CodeKata!</h2>
      <p class="text-gray-700">
        Start by <%= link_to "sending a duel challenge", new_duel_path, class: "text-blue-600 hover:underline" %>
        to a friend or <%= link_to "solving a challenge", challenges_path, class: "text-blue-600 hover:underline" %>.
      </p>
    </div>
  <% end %>
  
  <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
    <div class="bg-white border rounded p-6">
      <h3 class="text-lg font-semibold text-gray-700 mb-2">Challenges Solved</h3>
      <p class="text-4xl font-bold text-blue-600"><%= @challenges_solved %></p>
    </div>
    
    <div class="bg-white border rounded p-6">
      <h3 class="text-lg font-semibold text-gray-700 mb-2">Duels Won</h3>
      <p class="text-4xl font-bold text-green-600"><%= @duels_won %></p>
    </div>
    
    <div class="bg-white border rounded p-6">
      <h3 class="text-lg font-semibold text-gray-700 mb-2">Total Duels</h3>
      <p class="text-4xl font-bold text-purple-600"><%= @duels_played %></p>
    </div>
  </div>
  
  <% if @active_duels.any? %>
    <div class="mb-8">
      <h2 class="text-2xl font-bold mb-4">Active Duels</h2>
      <div class="space-y-4">
        <% @active_duels.each do |duel| %>
          <div class="bg-white border border-yellow-300 rounded p-4 flex justify-between items-center">
            <div>
              <p class="font-semibold"><%= duel.challenger.full_name %> vs <%= duel.opponent.full_name %></p>
              <p class="text-sm text-gray-600"><%= duel.challenge.name %></p>
            </div>
            <%= link_to "View", duel_path(duel), class: "px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700" %>
          </div>
        <% end %>
      </div>
    </div>
  <% end %>
  
  <% if @pending_duels.any? %>
    <div class="mb-8">
      <h2 class="text-2xl font-bold mb-4">Pending Duel Invitations</h2>
      <div class="space-y-4">
        <% @pending_duels.each do |duel| %>
          <div class="bg-white border border-blue-300 rounded p-4 flex justify-between items-center">
            <div>
              <p class="font-semibold"><%= duel.challenger.full_name %> challenged you to a duel</p>
              <p class="text-sm text-gray-600"><%= duel.challenge.name %></p>
            </div>
            <div class="flex gap-2">
              <% if duel.opponent_id == current_user.id %>
                <%= link_to "Accept", duel_path(duel), method: :patch, class: "px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700" %>
              <% end %>
              <%= link_to "View", duel_path(duel), class: "px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700" %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
  <% end %>
  
  <div>
    <h2 class="text-2xl font-bold mb-4">Featured Challenges</h2>
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <% @featured_challenges.each do |challenge| %>
        <div class="bg-white border rounded p-4">
          <h3 class="font-semibold mb-2"><%= challenge.name %></h3>
          <p class="text-sm text-gray-600 mb-3"><%= truncate(challenge.description, length: 100) %></p>
          <span class="inline-block px-2 py-1 bg-blue-100 text-blue-700 text-xs rounded">
            <%= challenge.difficulty.titleize %>
          </span>
        </div>
      <% end %>
    </div>
    <%= link_to "See All Challenges", challenges_path, class: "mt-4 inline-block text-blue-600 hover:underline" %>
  </div>
  
  <div class="mt-8 pt-8 border-t">
    <h2 class="text-2xl font-bold mb-4">Friends</h2>
    <% if @friends.any? %>
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <% @friends.each do |friend| %>
          <div class="text-center">
            <div class="w-16 h-16 rounded-full bg-gray-300 mx-auto mb-2"></div>
            <p class="font-semibold"><%= friend.full_name %></p>
            <%= link_to "Challenge", new_duel_path(opponent_slug: friend.slug), class: "text-sm text-blue-600 hover:underline" %>
          </div>
        <% end %>
      </div>
    <% else %>
      <p class="text-gray-600">You have no friends yet. <%= link_to "Send invitations", "#", class: "text-blue-600 hover:underline" %> to start.</p>
    <% end %>
  </div>
</div>
```

- [ ] **Step 3: Commit**

```bash
cd /home/dev08/work/CodeKata
git add app/views/home/
git commit -m "feat: add home dashboard with duel and challenge tracking"
```

---

## Task 10: Verify Admin Base Controller and Add Settings View

**Files:**
- Modify: `/app/controllers/admin/base_controller.rb`
- Create: `/app/views/admin/settings/show.html.erb`

- [ ] **Step 1: Check admin base controller**

```ruby
# app/controllers/admin/base_controller.rb should look like:
class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  private

  def require_admin
    redirect_to root_path unless current_user.admin?
  end
end
```

If `require_admin` doesn't exist, add it.

- [ ] **Step 2: Check if User model has admin? method**

```bash
grep "admin" /home/dev08/work/CodeKata/app/models/user.rb
```

If not, add to User model:

```ruby
def admin?
  # For now, check if user ID is 1 or add an admin column in future
  id == 1
end
```

- [ ] **Step 3: Create admin settings view directory**

```bash
mkdir -p /home/dev08/work/CodeKata/app/views/admin/settings
```

- [ ] **Step 4: Create admin settings view**

```erb
<!-- app/views/admin/settings/show.html.erb -->
<div class="container mx-auto px-4 py-8">
  <h1 class="text-3xl font-bold mb-6">Admin Settings</h1>
  
  <div class="max-w-2xl">
    <div class="bg-white border rounded p-6 mb-6">
      <h2 class="text-xl font-semibold mb-4">Feature Toggles</h2>
      
      <form action="<%= admin_settings_path %>" method="POST">
        <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
        <input type="hidden" name="setting" value="ai_hints_enabled">
        
        <div class="flex items-center justify-between">
          <label class="font-medium">AI Hints</label>
          <div class="flex items-center gap-4">
            <span class="text-sm text-gray-600">
              <%= @ai_hints_enabled ? "Enabled" : "Disabled" %>
            </span>
            <input 
              type="checkbox" 
              name="value" 
              value="true" 
              <%= "checked" if @ai_hints_enabled %>
              class="w-5 h-5"
              onchange="this.form.submit()">
          </div>
        </div>
      </form>
    </div>
    
    <%= link_to "Back to Home", home_path, class: "text-blue-600 hover:underline" %>
  </div>
</div>
```

- [ ] **Step 5: Commit**

```bash
cd /home/dev08/work/CodeKata
git add app/controllers/admin/base_controller.rb app/views/admin/settings/ app/models/user.rb
git commit -m "feat: add admin settings view for feature toggles"
```

---

## Task 11: Create Duel Channel for Real-Time Updates

**Files:**
- Modify: `/app/channels/duel_channel.rb` (should already exist from previous commit)

- [ ] **Step 1: Check existing DuelChannel**

```ruby
# Ensure /app/channels/duel_channel.rb looks like:
class DuelChannel < ApplicationCable::Channel
  def subscribed
    duel_id = params[:duel_id]
    stream_from "duel_#{duel_id}" if duel_id.present?
  end

  def unsubscribed
    stop_all_streams
  end
end
```

If it doesn't exist or is incomplete, create it as above.

- [ ] **Step 2: Verify it's in git**

```bash
cd /home/dev08/work/CodeKata
git status app/channels/duel_channel.rb
```

- [ ] **Step 3: Commit if changed**

```bash
cd /home/dev08/work/CodeKata
git add app/channels/duel_channel.rb
git commit -m "feat: ensure DuelChannel for real-time duel updates"
```

---

## Task 12: Update Database Configuration and Run Migrations

**Files:**
- Modify: `/config/database.yml`

- [ ] **Step 1: Check database.yml status**

```bash
cd /home/dev08/work/CodeKata
git status config/database.yml
```

If it shows as modified, check what changed:

```bash
git diff config/database.yml
```

- [ ] **Step 2: Run all migrations**

```bash
cd /home/dev08/work/CodeKata
rails db:migrate
```

Expected: All migrations run successfully

- [ ] **Step 3: Seed with test data (optional but helpful)**

Create `/db/seeds.rb` with sample challenges if needed:

```ruby
# db/seeds.rb sample additions
Challenge.find_or_create_by(name: "Add Two Numbers") do |c|
  c.description = "Write a function that takes two numbers and returns their sum."
  c.language = "ruby"
  c.method_template = "def add(a, b)\n  # your code here\nend"
  c.tests = [
    { input: "add(2, 3)", expected_output: "5" },
    { input: "add(0, 0)", expected_output: "0" },
    { input: "add(-1, 1)", expected_output: "0" }
  ].to_json
  c.difficulty = :easy
end
```

Run: `rails db:seed`

- [ ] **Step 4: Commit**

```bash
cd /home/dev08/work/CodeKata
git add config/database.yml
git commit -m "fix: update database configuration"
```

---

## Task 13: Integration Test - Verify All Pieces Work Together

**Files:**
- Create: `/test/integration/judge0_duel_flow_test.rb`

- [ ] **Step 1: Write integration test**

```ruby
# test/integration/judge0_duel_flow_test.rb
require "test_helper"

class Judge0DuelFlowTest < ActionDispatch::IntegrationTest
  def setup
    @user1 = users(:one)
    @user2 = users(:two)
    @challenge = challenges(:one)
    
    # Make them friends
    Invitation.create!(user: @user1, friend: @user2, confirmed: true)
  end

  test "user can create and accept a duel" do
    sign_in(@user1)
    
    # Create duel
    post duels_path, params: {
      opponent_id: @user2.id,
      challenge_id: @challenge.id
    }
    
    assert_response :redirect
    duel = Duel.last
    assert_equal @user1.id, duel.challenger_id
    assert_equal @user2.id, duel.opponent_id
    assert_equal "pending", duel.status
    
    # Opponent accepts
    sign_in(@user2)
    patch duel_path(duel)
    
    assert_response :redirect
    duel.reload
    assert_equal "active", duel.status
  end

  test "home dashboard displays correct stats" do
    sign_in(@user1)
    
    # Create and complete a challenge
    ChallengeCompletion.create!(user: @user1, challenge: @challenge)
    
    # Create a won duel
    duel = Duel.create!(
      challenger: @user1,
      opponent: @user2,
      challenge: @challenge,
      status: :completed,
      winner: @user1
    )
    
    get home_path
    
    assert_response :success
    assert_includes response.body, "1"  # challenges_solved
    assert_includes response.body, "1"  # duels_won
  end

  test "code evaluation broadcasts duel progress" do
    duel = Duel.create!(
      challenger: @user1,
      opponent: @user2,
      challenge: @challenge,
      status: :active
    )
    
    sign_in(@user1)
    
    # Mock Judge0Service
    results = {
      "test_0" => { passed: true, output: "5", expected: "5" },
      "test_1" => { passed: false, output: "3", expected: "8" }
    }
    
    Judge0Service.any_instance.stubs(:run_tests).returns(results)
    
    post evaluate_code_path(id: @challenge.id), params: {
      code: "def add(a,b)\n a+b\nend",
      duel_id: duel.id
    }
    
    assert_response :success
    response_json = JSON.parse(response.body)
    assert_equal results, response_json["output"]
  end
end
```

- [ ] **Step 2: Run integration test**

```bash
cd /home/dev08/work/CodeKata
rails test test/integration/judge0_duel_flow_test.rb
```

Expected: Tests pass or show what needs to be fixed

- [ ] **Step 3: Commit**

```bash
cd /home/dev08/work/CodeKata
git add test/integration/judge0_duel_flow_test.rb
git commit -m "test: add integration test for duel and code evaluation flow"
```

---

## Task 14: Update Routes and Verify Everything Works

**Files:**
- Verify: `/config/routes.rb`

- [ ] **Step 1: Check full routes output**

```bash
cd /home/dev08/work/CodeKata
rails routes
```

Verify these routes exist:
- `GET /home`
- `GET /duels/new`
- `POST /duels`
- `GET /duels/:id`
- `PATCH /duels/:id/accept`
- `POST /hints`
- `GET /admin/settings`
- `POST /admin/settings`

- [ ] **Step 2: Start Rails server and test**

```bash
cd /home/dev08/work/CodeKata
rails server
```

Visit:
- http://localhost:3000/ (should redirect to /home or show home)
- http://localhost:3000/home (should show dashboard)
- Create a duel between two users
- Check admin settings

- [ ] **Step 3: Fix any routing issues found**

If routes don't work, check routes.rb and fix

- [ ] **Step 4: Final commit**

```bash
cd /home/dev08/work/CodeKata
git status
# Add any remaining changed files
git add .
git commit -m "feat: complete Judge0 integration with duels, hints, and dashboard"
```

---

## Summary of Implementation

This plan completes:
✅ Judge0Service for code evaluation via external API
✅ GeminiService for AI-powered hints
✅ Duel model with full state management
✅ ChallengeCompletion tracking
✅ AppSetting for feature toggles
✅ Full routing for duels, hints, home, and admin
✅ Views for duel creation, active duels, and home dashboard
✅ Real-time updates via ActionCable DuelChannel
✅ Integration tests verifying end-to-end flow

**Testing checklist:**
- All models have validations and proper associations
- Services handle API errors gracefully
- Controllers return correct status codes
- Views display data correctly
- Duels transition through states (pending → active → completed)
- Code evaluation broadcasts progress to connected clients
- Admin can toggle AI hints feature

