# frozen_string_literal: true

require "much-rails-pub-sub/publisher"

class MuchRailsPubSub::TestPublisher < MuchRailsPubSub::Publisher
  def on_call
    event
  end
end
