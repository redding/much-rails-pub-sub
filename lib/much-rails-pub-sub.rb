# frozen_string_literal: true

require "much-rails"
require "much-rails-pub-sub/version"
require "much-rails-pub-sub/active_job_publisher"
require "much-rails-pub-sub/publish_job_behaviors"
require "much-rails-pub-sub/subscription"

module MuchRailsPubSub
  include MuchRails::Config

  add_config

  def self.publish(event_name, **event_params)
    config
      .publisher_class
      .call(event_name, event_params: event_params)
      .tap do |event|
        published_events << event
        config.logger.info(
          "[MuchRailsPubSub] Published #{event.name.inspect}:\n"\
          "  ID: #{event.id.inspect}\n"\
          "  PARAMS: #{event.params.inspect}",
        )
      end
  end

  def self.subscribe(event_name, job:)
    subscriptions <<
      MuchRailsPubSub::Subscription.new(
        event_name,
        job_class: config.constantize_job(job, type: :subscription),
      )
  end

  def self.published_events
    config.published_events
  end

  def self.subscriptions
    config.subscriptions
  end

  def self.load_subscriptions(subscriptions_file_path)
    config.constantize_publish_job_class
    # Use `Kernel.load` so we can stub and test this.
    Kernel.load(subscriptions_file_path)
  end

  def self.setup_test_publishing
    require "much-rails-pub-sub/test_publisher"

    config.published_events =
      MuchRailsPubSub::Config::TestingPublishedEvents.new
    config.publisher_class = MuchRailsPubSub::TestPublisher
  end

  class Config
    attr_reader :publish_job_class
    attr_accessor :publish_job, :published_events, :publisher_class, :logger

    def initialize
      @published_events = DefaultPublishedEvents.new
      @publisher_class = MuchRailsPubSub::ActiveJobPublisher
    end

    def constantize_publish_job_class
      @publish_job_class =
        constantize_job(publish_job, type: :publish).tap do |job_class|
          unless publish_job_class?(job_class)
            raise(
              TypeError,
              "Publish job classes must mixin MuchRailsPubSub::PublishJob. "\
              "The given job class, #{job_class.inspect}, does not.",
            )
          end
        end
    end

    def constantize_job(value, type:)
      begin
        value.to_s.constantize
      rescue NameError
        raise TypeError, "Unknown #{type} job class: #{value.inspect}."
      end
    end

    def subscriptions
      @subscriptions ||= Subscriptions.new
    end

    def publish_job_class?(job_class)
      !!(job_class < MuchRailsPubSub::PublishJobBehaviors)
    end

    class PublishedEvents < ::Array
      def <<(value)
        super

        value
      end
    end

    class DefaultPublishedEvents < PublishedEvents
      def <<(value)
        value
      end
    end

    TestingPublishedEvents = Class.new(PublishedEvents)

    class Subscriptions
      def initialize
        @subscriptions = Hash.new{ |hash, key| hash[key] = ::Set.new }
      end

      def for_event(event_name)
        @subscriptions[normalize_event_name(event_name)].to_a
      end

      def <<(subscription)
        @subscriptions[normalize_event_name(subscription.event_name)] <<
          subscription
      end

      def dispatch(publish_params)
        event_id = publish_params["event_id"]
        event_name = publish_params["event_name"]
        event_params = publish_params["event_params"]
        subscriptions = for_event(event_name)
        subscription_log_details =
          subscriptions
            .map{ |subscription|
              "  - #{subscription.job_class.inspect}"
            }
            .join("\n")

        subscriptions.each{ |subscription| subscription.call(event_params) }

        logger.info(
          "[MuchRailsPubSub] Dispatched #{subscriptions.size} subscription "\
          "job(s) for #{event_name.inspect} (#{event_id}):\n"\
          "#{subscription_log_details}",
        )
      end

      private

      def normalize_event_name(name)
        name.to_s.downcase
      end

      def logger
        MuchRailsPubSub.config.logger
      end
    end
  end
end
