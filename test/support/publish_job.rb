# frozen_string_literal: true

require "test/support/application_job"
require "much-rails-pub-sub"

class PublishJob < ApplicationJob
  include MuchRailsPubSub::PublishJobBehaviors
end
