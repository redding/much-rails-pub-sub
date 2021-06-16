# frozen_string_literal: true

require "much-rails-pub-sub/publisher"

class MuchRailsPubSub::ActiveJobPublisher < MuchRailsPubSub::Publisher
  def on_call
    @publshed_job_id ||=
      MuchRailsPubSub.config.publish_job_class.perform_later(publish_params)

    event
  end
end
