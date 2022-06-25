# This file was generated by the `rails generate rspec:install` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration

# Don't calculate coverage when running single tests or recording API examples
unless ENV.fetch('SKIP_COVERAGE', false) || ENV.fetch('APIPIE_RECORD', false) || RSpec.configuration.files_to_run.count <= 1
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_group("Controllers") { |src| src.filename.include?('app/controllers') and src.filename.exclude?('app/controllers/api') }
    add_group "Presenters", "app/presenters"
    add_group "Concerns", "app/concerns"
    add_group "API", "app/controllers/api"
    add_group "Services", "app/services"
    add_group "Exceptions", "app/exceptions"
    SimpleCov.groups.delete('Channels')
    changed_files = `git status --untracked=all --porcelain`
    unless changed_files.empty?
      add_group 'Changed' do |source_file|
        changed_files.split("\n").detect do |status_and_filename|
          _, filename = status_and_filename.split(' ', 2)
          source_file.filename.ends_with?(filename)
        end
      end
    end
    enable_coverage :branch
    minimum_coverage line: 99.9, branch: 91.73
  end
end

require 'factory_bot_rails'
require 'rails_helper'
require 'support/spec_test_helper'
require 'support/spec_feature_helper'
require 'support/api_test_helper'
require 'support/posts_controller_shared'

require 'webdrivers'
require 'selenium/webdriver'

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument("--user-data-dir=#{ENV['CHROMEDRIVER_CONFIG']}") if ENV['CHROMEDRIVER_CONFIG']
  # options.add_argument('--disable-popup-blocking')
  options.add_argument('--window-size=1366,768')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :headless_chrome

Capybara.configure do |config|
  config.server = :puma, { Silent: true }
end

RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  config.include FactoryBot::Syntax::Methods
  config.include SpecTestHelper, :type => :controller
  config.include ApiTestHelper, :type => :controller
  config.include SpecFeatureHelper, :type => :feature

  config.filter_run :show_in_doc => true if ENV['APIPIE_RECORD']

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # The settings below are suggested to provide a good initial experience
  # with RSpec, but feel free to customize to your heart's content.
  # This allows you to limit a spec run to individual examples or groups
  # you care about by tagging them with `:focus` metadata. When nothing
  # is tagged with `:focus`, all examples get run. RSpec also provides
  # aliases for `it`, `describe`, and `context` that include `:focus`
  # metadata: `fit`, `fdescribe` and `fcontext`, respectively.
  config.filter_run_when_matching :focus

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  #   - http://rspec.info/blog/2012/06/rspecs-new-expectation-syntax/
  #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://rspec.info/blog/2014/05/notable-changes-in-rspec-3/#zero-monkey-patching-mode
  config.disable_monkey_patching!

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  # if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    # config.default_formatter = "doc"
  # end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = ENV.fetch('NUM_PROFILE', 10).to_i

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = ENV['APIPIE_RECORD'] ? :defined : :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  config.before(:suite) do
    # make 5 boards so site_testing doesn't screw up tests
    user = FactoryBot.create(:user)
    5.times do
      board = FactoryBot.create(:board, creator: user)
      Audited.audit_class.as_user(user) { board.destroy! }
    end
    user.destroy!
  end

  if ENV['APIPIE_RECORD']
    config.before(:suite) do
      DatabaseCleaner.strategy = :truncation
      DatabaseCleaner.clean_with(:truncation)
    end

    config.around(:each) do |example|
      time = Time.new(2019, 12, 25, 21, 34, 56, 0)
      DatabaseCleaner.cleaning do
        Timecop.freeze(time) do
          example.run
        end
      end
    end
  end
end

RSpec::Matchers.define :be_the_same_time_as do |expected|
  match do |actual|
    expected.in_time_zone.to_s(:iso8601) == actual.in_time_zone.to_s(:iso8601)
  end

  failure_message do |actual|
    <<~FAILURE
      expected #{actual} to be the same time as #{expected}
      compared: #{actual.in_time_zone.to_s(:iso8601)}
          with: #{expected.in_time_zone.to_s(:iso8601)}
    FAILURE
  end

  failure_message_when_negated do |actual|
    <<~FAILURE
      expected #{actual} not to be the same time as #{expected}
      compared: #{actual.in_time_zone.to_s(:iso8601)}
          with: #{expected.in_time_zone.to_s(:iso8601)}
    FAILURE
  end
end

RSpec::Matchers.define_negated_matcher :not_change, :change

# Monkey patches the controller response objects to return JSON
module ActionDispatch # rubocop:disable Style/ClassAndModuleChildren
  class TestResponse
    def json
      @json ||= JSON.parse(self.body)
    end
  end
end

require 'webmock/rspec'
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: "chromedriver.storage.googleapis.com",
)

require "fakeredis/rspec"

# disable auditing by default unless specifically turned on for a test
Post.auditing_enabled = false
Reply.auditing_enabled = false
Character.auditing_enabled = false
Block.auditing_enabled = false
