# frozen_string_literal: true

require "much-rails-pub-sub"

class MuchRailsPubSub::Subscription
  attr_reader :event_name, :job_class

  def initialize(event_name, job_class:)
    @event_name = event_name
    @job_class = job_class

    unless job_class.respond_to?(:perform_later)
      raise(
        ArgumentError,
        "Invalid job class #{job_class.inspect}: it does not respond to "\
        "the :perform_later method.",
      )
    end
  end

  def call(params)
    job_class.perform_later(params)
  end

  def hash
    job_class.hash
  end

  def eql?(other)
    job_class.eql?(other.job_class)
  end

  def ==(other)
    if other.is_a?(self.class)
      event_name == other.event_name && job_class == other.job_class
    else
      super
    end
  end
end
