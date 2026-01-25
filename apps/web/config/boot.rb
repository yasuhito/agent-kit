ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)
if ARGV.first&.start_with?("test")
  ENV["DEFAULT_TEST_EXCLUDE"] ||= "test/{dummy,fixtures}/**/*_test.rb"
end

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
