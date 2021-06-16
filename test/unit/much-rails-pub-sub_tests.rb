# frozen_string_literal: true

require "assert"
require "much-rails-pub-sub"

require "test/support/fake_logger"
require "test/support/application_job"

module MuchRailsPubSub
  class UnitTests < Assert::Context
    desc "MuchRailsPubSub"
    subject{ unit_class }

    let(:unit_class){ MuchRailsPubSub }

    let(:event_name){ "something_happened_v1" }
    let(:event_params){ { some: "thing" } }

    let(:job_value){ "MuchRailsPubSub::TestPublishJob" }
    let(:job_class){ TestPublishJob }

    let(:logger1){ FakeLogger.new }

    should have_imeths :config
    should have_imeths :publish, :subscribe
    should have_imeths :published_events, :subscriptions
    should have_imeths :load_subscriptions, :setup_test_publishing

    should "be configured as expected" do
      assert_that(subject).includes(MuchRails::Config)
    end

    should "know its attributes" do
      assert_that(subject.config).is_a?(unit_class::Config)
    end
  end

  class PublishMethodTests < UnitTests
    desc ".publish"

    setup do
      Assert.stub(unit_class.config, :logger){ logger1 }

      @publisher_calls = []
      Assert.stub_tap_on_call(
        unit_class.config.publisher_class,
        :call,
      ) do |_, call|
        @publisher_calls << call
      end

      Assert.stub(unit_class.config, :published_events){ published_events1 }
    end
  end

  class DefaultPublishedEventsPublishTests < PublishMethodTests
    desc "when using the DefaultPublishedEvents"

    let(:published_events1){ unit_class::Config::DefaultPublishedEvents.new }

    should "call the Publish service without storing the published event" do
      event = subject.publish(event_name, **event_params)
      assert_that(event).is_a?(MuchRailsPubSub::Event)

      assert_that(@publisher_calls.size).equals(1)
      assert_that(@publisher_calls.last.pargs).equals([event_name])
      assert_that(@publisher_calls.last.kargs)
        .equals(event_params: event_params)
      assert_that(subject.published_events).is_empty
    end
  end

  class TestingPublishedEventsPublishTests < PublishMethodTests
    desc "when using the TestingPublishedEvents"

    let(:published_events1){ unit_class::Config::TestingPublishedEvents.new }

    should "call the Publish service and store the published event" do
      event = subject.publish(event_name, **event_params)
      assert_that(event).is_a?(MuchRailsPubSub::Event)

      assert_that(@publisher_calls.size).equals(1)
      assert_that(@publisher_calls.last.pargs).equals([event_name])
      assert_that(@publisher_calls.last.kargs)
        .equals(event_params: event_params)
      assert_that(subject.published_events.last).is(event)
    end
  end

  class SubscribeMethodTests < UnitTests
    desc ".subscribe"

    setup do
      Assert.stub(unit_class.config, :subscriptions){ subscriptions1 }
    end

    let(:subscriptions1){ unit_class::Config::Subscriptions.new }

    should "push a subscription on to the configured subscriptions" do
      subject.subscribe(event_name, job: job_value)

      assert_that(subscriptions1.for_event(event_name).size).equals(1)
      assert_that(subscriptions1.for_event(event_name).last)
        .equals(unit_class::Subscription.new(event_name, job_class: job_class))
    end
  end

  class LoadSubscriptionsTests < UnitTests
    desc ".load_subscriptions"

    setup do
      Assert.stub_on_call(
        subject.config,
        :constantize_publish_job_class,
      ) do |call|
        @constantize_publish_job_class_call = call
      end
      Assert.stub_on_call(Kernel, :load){ |call| @load_call = call }
    end

    let(:subscriptions_file_path){ Factory.file_path }

    should "constantize the publish job class and "\
           "load the subscriptions file path" do
      subject.load_subscriptions(subscriptions_file_path)
      assert_that(@constantize_publish_job_class_call).is_not_nil
      assert_that(@load_call.args).equals([subscriptions_file_path])
    end
  end

  class ConfigTests < UnitTests
    desc "Config"
    subject{ config_class }

    let(:config_class){ unit_class::Config }
  end

  class ConfigInitTests < ConfigTests
    desc "when init"
    subject{ config_class.new }

    let(:type_value){ :some_type_value }

    should have_readers :publish_job_class
    should have_accessors :publish_job, :published_events, :publisher_class
    should have_accessors :logger

    should "know how to constantize its publish job class" do
      subject.publish_job = job_value
      assert_that(subject.publish_job_class).is_nil

      subject.constantize_publish_job_class
      assert_that(subject.publish_job_class).equals(job_class)
    end

    should "complain if it can't constantize the publish job class" do
      ex =
        assert_that{ subject.constantize_publish_job_class }.raises(TypeError)
      assert_that(ex.message)
        .equals("Unknown publish job class: nil.")

      subject.publish_job = "MuchRailsPubSub::UnknownPublishJob"
      ex =
        assert_that{ subject.constantize_publish_job_class }.raises(TypeError)
      assert_that(ex.message)
        .equals("Unknown publish job class: #{subject.publish_job.inspect}.")

      subject.publish_job = "MuchRailsPubSub::TestNonPublishJob"
      ex =
        assert_that{ subject.constantize_publish_job_class }.raises(TypeError)
      assert_that(ex.message)
        .equals(
          "Publish job classes must mixin MuchRailsPubSub::PublishJob. "\
          "The given job class, MuchRailsPubSub::TestNonPublishJob, does not.",
        )
    end

    should "constantize valid job class values" do
      assert_that(subject.constantize_job(job_value, type: type_value))
        .equals(job_class)
    end

    should "complain when constantizing invalid job class values" do
      ex =
        assert_that{
          subject.constantize_job("SomeUnknownInvalidClass", type: type_value)
        }.raises(TypeError)
      assert_that(ex.message).includes("Unknown #{type_value} job class: ")
    end

    should "know if a given job class is a publish job class or not" do
      assert_that(subject.publish_job_class?(TestPublishJob)).is_true
      assert_that(subject.publish_job_class?(TestNonPublishJob)).is_false
    end
  end

  class SubscriptionsTests < ConfigTests
    desc "Subscriptions"
    subject{ subscriptions_class }

    let(:subscriptions_class){ config_class::Subscriptions }
  end

  class SubscriptionsInitSetupTests < SubscriptionsTests
    desc "when init"
    subject{ subscriptions_class.new }

    setup{ subject << subscription1 }

    let(:fake_job_class){ FakeJobClass.new }
    let(:publish_params) do
      {
        "event_name" => event_name,
        "event_params" => event_params,
      }
    end
  end

  class SubscriptionsInitTests < SubscriptionsInitSetupTests
    let(:subscription1) do
      MuchRailsPubSub::Subscription.new(event_name, job_class: fake_job_class)
    end

    should have_imeths :for_event, :<<, :dispatch

    should "know which subscriptions are configured for an event name" do
      assert_that(subject.for_event(event_name).size).equals(1)
      assert_that(subject.for_event(event_name).last).equals(subscription1)
    end

    should "not add duplicate subscriptions" do
      subject << subscription1
      subject << subscription1

      assert_that(subject.for_event(event_name).size).equals(1)
    end
  end

  class DispatchSubscriptionsTests < SubscriptionsInitSetupTests
    desc "when init and dispacting subscriptions"

    setup do
      Assert.stub(MuchRailsPubSub.config, :logger){ logger1 }
    end

    let(:subscription1) do
      FakeSubscription.new(event_name, job_class: fake_job_class)
    end

    should "dispatch by calling each subscription for the event name" do
      subject.dispatch(publish_params)

      subject.for_event(event_name).each do |subscription|
        assert_that(subscription.calls.size).equals(1)
        assert_that(subscription.calls.last.args).equals([event_params])
      end
    end
  end

  class FakeSubscription < MuchRailsPubSub::Subscription
    attr_reader :calls
    def initialize(*args)
      super
      @calls = []
    end

    def call(*args)
      @calls << Assert::StubCall.new(*args)
    end
  end

  class FakeJobClass
    attr_reader :perform_calls

    def initialize
      @perform_calls = []
    end

    def perform_later(*args)
      @perform_calls << Assert::StubCall.new(*args)
    end
  end

  class TestPublishJob < ApplicationJob
    include MuchRailsPubSub::PublishJobBehaviors
  end

  class TestNonPublishJob < ApplicationJob
  end
end
