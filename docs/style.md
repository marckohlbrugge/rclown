# rclown Style Guide

Style conventions for rclown, following 37signals/Basecamp patterns from Fizzy and Campfire codebases.

---

## Philosophy

1. **Rich domain models** over service objects
2. **CRUD controllers** over custom actions
3. **Concerns** for horizontal code sharing
4. **Records as state** over boolean columns
5. **Database-backed everything** (no Redis)
6. **Vanilla Rails is plenty** - maximize what Rails gives you
7. **Ship to learn** - prototype quality is valid, refine later

---

## Routing

### Everything is CRUD

Every action maps to a CRUD verb. When something doesn't fit, create a new resource.

```ruby
# BAD: Custom actions
resources :backups do
  post :run
  post :cancel
  post :enable
  post :disable
end

# GOOD: New resources for each action
resources :backups do
  scope module: :backups do
    resource :execution      # POST to run backup now
    resource :cancellation   # POST to cancel running backup
    resource :enablement     # POST to enable, DELETE to disable
    resources :runs          # History of backup executions
  end
end
```

### rclown Route Structure

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root "dashboard#show"

  resource :dashboard, only: :show

  resources :providers do
    scope module: :providers do
      resource :connection_test    # POST to test credentials
      resources :buckets           # GET to list, POST to import as Storage
    end
  end

  resources :storages

  resources :backups do
    scope module: :backups do
      resource :execution          # POST to run now
      resource :cancellation       # POST to cancel running
      resource :enablement         # POST/DELETE to enable/disable
      resource :dry_run            # POST to run in dry-run mode
      resources :runs, only: [:index, :show]
    end
  end

  # Standalone route for BackupRun details
  resources :backup_runs, only: :show

  resource :health, only: :show
  resource :settings, only: [:show, :update]

  get "up", to: "rails/health#show", as: :rails_health_check
end
```

### Naming: Verbs Become Nouns

| Action | Resource |
|--------|----------|
| Run a backup | `backup.execution` |
| Cancel a backup | `backup.cancellation` |
| Enable/disable | `backup.enablement` |
| Test connection | `provider.connection_test` |
| Import bucket | `provider.bucket` (create) |

---

## Controllers

### Thin Controllers, Rich Models

Controllers should be thin orchestrators. Business logic lives in models.

```ruby
# GOOD: Controller just orchestrates
class Backups::ExecutionsController < ApplicationController
  include BackupScoped

  def create
    @backup.execute  # All logic in model

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @backup }
    end
  end
end

# BAD: Business logic in controller
class Backups::ExecutionsController < ApplicationController
  def create
    @backup = Backup.find(params[:backup_id])

    if @backup.running?
      redirect_to @backup, alert: "Already running"
      return
    end

    run = @backup.runs.create!(status: :pending)
    ExecuteBackupJob.perform_later(run)
    # etc...
  end
end
```

### Controller Concerns for Scoping

```ruby
# app/controllers/concerns/backup_scoped.rb
module BackupScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_backup
  end

  private
    def set_backup
      @backup = Backup.find(params[:backup_id])
    end
end

# app/controllers/concerns/provider_scoped.rb
module ProviderScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_provider
  end

  private
    def set_provider
      @provider = Provider.find(params[:provider_id])
    end
end
```

### Controller File Organization

```
app/controllers/
  application_controller.rb
  dashboard_controller.rb
  providers_controller.rb
  providers/
    buckets_controller.rb
    connection_tests_controller.rb
  storages_controller.rb
  backups_controller.rb
  backups/
    executions_controller.rb
    cancellations_controller.rb
    enablements_controller.rb
    dry_runs_controller.rb
    runs_controller.rb
  backup_runs_controller.rb
  health_controller.rb
  settings_controller.rb
  concerns/
    authentication.rb
    backup_scoped.rb
    provider_scoped.rb
```

### Response Patterns

```ruby
class Backups::ExecutionsController < ApplicationController
  include BackupScoped

  def create
    @run = @backup.execute

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @backup, notice: "Backup started" }
    end
  end
end
```

---

## Models

### Heavy Use of Concerns

Break models into focused concerns, each handling one aspect:

```ruby
# app/models/backup.rb
class Backup < ApplicationRecord
  include Executable, Schedulable, Enableable, Cancellable

  belongs_to :source_storage, class_name: "Storage"
  belongs_to :destination_storage, class_name: "Storage"

  has_many :runs, class_name: "BackupRun", dependent: :destroy

  validates :name, presence: true
  validate :source_and_destination_differ

  private
    def source_and_destination_differ
      if source_storage_id == destination_storage_id
        errors.add(:destination_storage, "must be different from source")
      end
    end
end
```

### Concern Structure: Self-Contained Behavior

Each concern includes associations, scopes, and methods:

```ruby
# app/models/backup/executable.rb
module Backup::Executable
  extend ActiveSupport::Concern

  def execute(dry_run: false)
    return if running? && !dry_run

    runs.create!(dry_run: dry_run).tap do |run|
      run.execute_later
    end
  end

  def running?
    runs.running.exists?
  end

  def last_run
    runs.completed.order(finished_at: :desc).first
  end
end

# app/models/backup/schedulable.rb
module Backup::Schedulable
  extend ActiveSupport::Concern

  included do
    enum :schedule, { daily: "daily", weekly: "weekly" }
  end

  def next_run_at
    return nil unless enabled?

    case schedule
    when "daily"
      last_run_at ? last_run_at + 1.day : Time.current
    when "weekly"
      last_run_at ? last_run_at + 1.week : Time.current
    end
  end

  def due?
    enabled? && (next_run_at.nil? || next_run_at <= Time.current)
  end
end

# app/models/backup/enableable.rb
module Backup::Enableable
  extend ActiveSupport::Concern

  included do
    scope :enabled, -> { where(enabled: true) }
    scope :disabled, -> { where(enabled: false) }
  end

  def enable
    update!(enabled: true)
  end

  def disable
    update!(enabled: false)
  end
end

# app/models/backup/cancellable.rb
module Backup::Cancellable
  extend ActiveSupport::Concern

  def cancel
    runs.running.find_each(&:cancel)
  end
end
```

### State as Records (When Appropriate)

For simple states like `enabled`, a boolean is fine. For states that need metadata (who, when, context), use records:

```ruby
# Boolean is fine for simple toggle
class Backup < ApplicationRecord
  # enabled: boolean column
  scope :enabled, -> { where(enabled: true) }
end

# Record for state with metadata
class BackupRun < ApplicationRecord
  # status enum tracks state
  # started_at, finished_at track timing
  # rclone_pid tracks process
  # exit_code, raw_log track results
end
```

### Default Values via Lambdas

```ruby
class BackupRun < ApplicationRecord
  belongs_to :backup

  enum :status, {
    pending: "pending",
    running: "running",
    success: "success",
    failed: "failed",
    cancelled: "cancelled",
    skipped: "skipped"
  }, default: :pending
end
```

### Model File Organization

```
app/models/
  application_record.rb
  current.rb
  provider.rb
  provider/
    cloudflare_r2.rb         # Provider type specifics if needed
    backblaze_b2.rb
    amazon_s3.rb
    rclone_configurable.rb   # Generates rclone config
    bucket_discoverable.rb   # Lists buckets
  storage.rb
  backup.rb
  backup/
    executable.rb
    schedulable.rb
    enableable.rb
    cancellable.rb
  backup_run.rb
  backup_run/
    process_manageable.rb    # PID tracking, signals
    loggable.rb              # Log capture
  rclone/
    executor.rb              # PORO: Runs rclone commands
    config_generator.rb      # PORO: Creates temp config
```

### Scope Naming: Business-Focused

```ruby
class BackupRun < ApplicationRecord
  # Good - business-focused
  scope :running, -> { where(status: :running) }
  scope :completed, -> { where(status: [:success, :failed, :cancelled]) }
  scope :successful, -> { where(status: :success) }
  scope :failed, -> { where(status: :failed) }
  scope :recent, -> { order(created_at: :desc).limit(30) }

  # Avoid SQL-ish names like:
  # scope :with_status_running
  # scope :not_pending
end
```

---

## Jobs

### Shallow Jobs

Jobs just call model methods - no business logic in jobs:

```ruby
# app/jobs/execute_backup_job.rb
class ExecuteBackupJob < ApplicationJob
  queue_as :backups

  def perform(backup_run)
    backup_run.execute
  end
end

# app/jobs/schedule_backups_job.rb
class ScheduleBackupsJob < ApplicationJob
  queue_as :scheduler

  def perform
    Backup.enabled.due.find_each do |backup|
      backup.execute
    end
  end
end

# app/jobs/backup_failure_notification_job.rb
class BackupFailureNotificationJob < ApplicationJob
  queue_as :notifications

  def perform(backup_run)
    backup_run.notify_failure
  end
end
```

### The `_later` and `_now` Convention

```ruby
# app/models/backup_run.rb
class BackupRun < ApplicationRecord
  # Called by job - the actual work
  def execute
    running!
    result = Rclone::Executor.new(self).run
    record_result(result)
  end

  # Enqueues the job
  def execute_later
    ExecuteBackupJob.perform_later(self)
  end

  # Called by job
  def notify_failure
    return unless failed?
    BackupMailer.failure(self).deliver_now
  end

  def notify_failure_later
    BackupFailureNotificationJob.perform_later(self)
  end
end
```

### Error Handling

```ruby
# app/jobs/concerns/rclone_error_handling.rb
module RcloneErrorHandling
  extend ActiveSupport::Concern

  included do
    # Retry on transient system errors
    retry_on Errno::ENOENT, wait: :polynomially_longer, attempts: 3
    retry_on Errno::ECONNREFUSED, wait: :polynomially_longer, attempts: 3

    # Don't retry on permanent failures - let them fail
    # The BackupRun will be marked as failed
  end
end
```

### Job Organization

```
app/jobs/
  application_job.rb
  execute_backup_job.rb
  schedule_backups_job.rb
  backup_failure_notification_job.rb
  cleanup_old_runs_job.rb
  concerns/
    rclone_error_handling.rb
```

---

## Service Objects: Avoid Them (Usually)

37signals avoids service objects. Instead:

1. Put business logic in **models**
2. Use **concerns** to organize model code
3. Use **POROs under model namespaces** for complex operations

### When to Use POROs

POROs are model-adjacent, not controller-adjacent:

```ruby
# app/models/rclone/executor.rb
# Complex operation that orchestrates rclone execution
class Rclone::Executor
  attr_reader :backup_run

  def initialize(backup_run)
    @backup_run = backup_run
  end

  def run
    config_file = generate_config
    execute_rclone(config_file)
  ensure
    cleanup_config(config_file)
  end

  private
    def generate_config
      Rclone::ConfigGenerator.new(backup_run.backup).generate
    end

    def execute_rclone(config_file)
      # Subprocess management
    end

    def cleanup_config(config_file)
      config_file&.unlink
    end
end

# app/models/rclone/config_generator.rb
# Generates temporary rclone config from Provider credentials
class Rclone::ConfigGenerator
  attr_reader :backup

  def initialize(backup)
    @backup = backup
  end

  def generate
    Tempfile.new(["rclone", ".conf"]).tap do |file|
      file.write(config_contents)
      file.flush
    end
  end

  private
    def config_contents
      <<~CONFIG
        [source]
        #{provider_config(backup.source_storage.provider)}

        [destination]
        #{provider_config(backup.destination_storage.provider)}
      CONFIG
    end

    def provider_config(provider)
      # Generate provider-specific config
    end
end
```

---

## Views

### Turbo Streams for Updates

```erb
<%# app/views/backups/executions/create.turbo_stream.erb %>
<%= turbo_stream.replace dom_id(@backup, :status),
    partial: "backups/status",
    locals: { backup: @backup } %>

<%= turbo_stream.prepend dom_id(@backup, :runs),
    partial: "backup_runs/run",
    locals: { run: @run } %>
```

### Prefer Locals Over Instance Variables

```erb
<%# Good - explicit dependencies %>
<%= render "backups/status", backup: backup %>

<%# Avoid - implicit dependencies %>
<%= render "backups/status" %>
```

### Partial Naming

```
app/views/
  backups/
    _backup.html.erb          # Single backup card
    _form.html.erb            # Backup form
    _status.html.erb          # Status badge/indicator
    _history.html.erb         # 30-day history dots
  backup_runs/
    _run.html.erb             # Single run in list
    _log.html.erb             # Log viewer
  providers/
    _provider.html.erb
    _form.html.erb
    _credentials_form.html.erb
  storages/
    _storage.html.erb
    _form.html.erb
```

### DOM ID Conventions

```erb
<div id="<%= dom_id(backup) %>">              <%# backup_123 %>
<div id="<%= dom_id(backup, :status) %>">     <%# status_backup_123 %>
<div id="<%= dom_id(backup, :runs) %>">       <%# runs_backup_123 %>
<div id="<%= dom_id(backup, :history) %>">    <%# history_backup_123 %>
```

### Lazy Loading Frames

```erb
<%# Lazy load bucket list %>
<%= turbo_frame_tag dom_id(@provider, :buckets),
    src: provider_buckets_path(@provider),
    loading: :lazy do %>
  <p>Loading buckets...</p>
<% end %>
```

---

## Testing

### Minitest Over RSpec

Use Rails defaults. No RSpec DSL.

### Fixtures Over Factories

```yaml
# test/fixtures/providers.yml
cloudflare:
  name: "Cloudflare R2"
  provider_type: cloudflare_r2
  endpoint: "https://xxx.r2.cloudflarestorage.com"
  access_key_id: "test_access_key"
  secret_access_key: "test_secret_key"

backblaze:
  name: "Backblaze B2"
  provider_type: backblaze_b2
  access_key_id: "test_access_key"
  secret_access_key: "test_secret_key"

# test/fixtures/storages.yml
source_bucket:
  provider: cloudflare
  bucket_name: "my-source-bucket"

destination_bucket:
  provider: backblaze
  bucket_name: "my-backup-bucket"

# test/fixtures/backups.yml
daily_backup:
  name: "Daily R2 to B2"
  source_storage: source_bucket
  destination_storage: destination_bucket
  schedule: daily
  enabled: true
```

### Test Structure

```ruby
# test/models/backup_test.rb
class BackupTest < ActiveSupport::TestCase
  setup do
    @backup = backups(:daily_backup)
  end

  test "execute creates a pending run" do
    assert_difference "BackupRun.count", 1 do
      @backup.execute
    end

    assert @backup.runs.last.pending?
  end

  test "execute skips if already running" do
    @backup.runs.create!(status: :running)

    assert_no_difference "BackupRun.count" do
      @backup.execute
    end
  end

  test "source and destination must differ" do
    @backup.destination_storage = @backup.source_storage

    assert_not @backup.valid?
    assert_includes @backup.errors[:destination_storage], "must be different from source"
  end
end
```

### Integration Tests

```ruby
# test/controllers/backups/executions_controller_test.rb
class Backups::ExecutionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @backup = backups(:daily_backup)
  end

  test "create starts a backup" do
    assert_difference "BackupRun.count", 1 do
      post backup_execution_path(@backup)
    end

    assert_redirected_to @backup
  end

  test "create as turbo_stream" do
    assert_difference "BackupRun.count", 1 do
      post backup_execution_path(@backup), as: :turbo_stream
    end

    assert_response :success
  end
end
```

### Testing Jobs

```ruby
# test/jobs/execute_backup_job_test.rb
class ExecuteBackupJobTest < ActiveSupport::TestCase
  test "executes the backup run" do
    run = backup_runs(:pending_run)

    ExecuteBackupJob.perform_now(run)

    assert run.reload.completed?
  end
end
```

---

## Naming Conventions

### Domain Terms

| Term | Description | Model |
|------|-------------|-------|
| Provider | Credentials + config for storage service | `Provider` |
| Storage | A specific bucket (with optional prefix) | `Storage` |
| Backup | Configuration linking source to destination | `Backup` |
| BackupRun | One execution of a backup | `BackupRun` |

### Controller Naming

| Action | Controller | HTTP |
|--------|------------|------|
| Run backup | `Backups::ExecutionsController#create` | POST |
| Cancel backup | `Backups::CancellationsController#create` | POST |
| Enable backup | `Backups::EnablementsController#create` | POST |
| Disable backup | `Backups::EnablementsController#destroy` | DELETE |
| Test provider | `Providers::ConnectionTestsController#create` | POST |
| List buckets | `Providers::BucketsController#index` | GET |
| Import bucket | `Providers::BucketsController#create` | POST |

### Status Naming

```ruby
# BackupRun statuses
enum :status, {
  pending: "pending",     # Queued, waiting to start
  running: "running",     # Currently executing
  success: "success",     # Completed successfully
  failed: "failed",       # Completed with errors
  cancelled: "cancelled", # Stopped by user
  skipped: "skipped"      # Skipped (e.g., already running)
}
```

---

## File Organization Summary

```
app/
  controllers/
    application_controller.rb
    concerns/
      authentication.rb
      backup_scoped.rb
      provider_scoped.rb
    backups_controller.rb
    backups/
      executions_controller.rb
      cancellations_controller.rb
      enablements_controller.rb
      dry_runs_controller.rb
      runs_controller.rb
    providers_controller.rb
    providers/
      buckets_controller.rb
      connection_tests_controller.rb
    storages_controller.rb
    backup_runs_controller.rb
    dashboard_controller.rb
    health_controller.rb
    settings_controller.rb

  models/
    application_record.rb
    current.rb
    provider.rb
    provider/
      rclone_configurable.rb
      bucket_discoverable.rb
    storage.rb
    backup.rb
    backup/
      executable.rb
      schedulable.rb
      enableable.rb
      cancellable.rb
    backup_run.rb
    backup_run/
      process_manageable.rb
      loggable.rb
    rclone/
      executor.rb
      config_generator.rb

  jobs/
    application_job.rb
    execute_backup_job.rb
    schedule_backups_job.rb
    backup_failure_notification_job.rb
    cleanup_old_runs_job.rb
    concerns/
      rclone_error_handling.rb

  views/
    layouts/
    backups/
    backup_runs/
    providers/
    storages/
    dashboard/
    health/
    settings/

  mailers/
    application_mailer.rb
    backup_mailer.rb

test/
  fixtures/
    providers.yml
    storages.yml
    backups.yml
    backup_runs.yml
  models/
    provider_test.rb
    storage_test.rb
    backup_test.rb
    backup_run_test.rb
  controllers/
    backups_controller_test.rb
    backups/
      executions_controller_test.rb
    providers_controller_test.rb
  jobs/
    execute_backup_job_test.rb
    schedule_backups_job_test.rb
```

---

## Quick Reference

### When in Doubt

1. **Add a new controller** instead of a custom action
2. **Put logic in models** instead of controllers or services
3. **Create a concern** when behavior is shared or model is large
4. **Use fixtures** for test data
5. **Name things for business concepts**, not implementation details
6. **Keep jobs shallow** - they just call model methods
