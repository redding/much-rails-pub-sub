# frozen_string_literal: true

# Add the root dir to the load path.
$LOAD_PATH.unshift(File.expand_path("../..", __FILE__))

# Require pry for debugging (`binding.pry`).
require "pry"

require "test/support/factory"
require "test/support/publish_job"
require "much-rails-pub-sub"

MuchRailsPubSub.configure do |config|
  config.publish_job = "PublishJob"
end

MuchRailsPubSub.load_subscriptions("test/support/pub_sub.rb")
