# frozen_string_literal: true

require "much-rails-pub-sub"
require "much-rails-pub-sub/event"

class MuchRailsPubSub::Publisher
  include MuchRails::CallMethod

  attr_reader :event

  def initialize(event_name, event_params:)
    @event = MuchRailsPubSub::Event.new(event_name, params: event_params)
  end

  def on_call
    raise NotImplementedError
  end

  def event_id
    event.id
  end

  def event_name
    event.name
  end

  def event_params
    event.params
  end

  private

  def publish_params
    {
      "event_id" => event_id,
      "event_name" => event_name,
      "event_params" => event_params,
    }
  end
end
