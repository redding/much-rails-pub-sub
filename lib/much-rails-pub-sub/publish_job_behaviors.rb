# frozen_string_literal: true

require "much-rails-pub-sub"

module MuchRailsPubSub::PublishJobBehaviors
  include MuchRails::Mixin

  mixin_instance_methods do
    def perform(publish_params)
      MuchRailsPubSub.subscriptions.dispatch(publish_params)
    end
  end
end
