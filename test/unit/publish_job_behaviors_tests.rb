# frozen_string_literal: true

require "assert"
require "much-rails-pub-sub/publish_job_behaviors"

require "test/support/application_job"

module MuchRailsPubSub::PublishJobBehaviors
  class UnitTests < Assert::Context
    desc "MuchRailsPubSub::Publish::JobBehaviors"
    subject{ unit_module }

    let(:unit_module){ MuchRailsPubSub::PublishJobBehaviors }

    let(:event_name){ "something_happened_v1" }
    let(:event_params){ { some: "thing" } }

    should "be configured as expected" do
      assert_that(subject).includes(MuchRails::Mixin)
    end
  end

  class ReceiverTests < UnitTests
    desc "receiver"
    subject{ receiver_class }

    let(:receiver_class) do
      Class.new(ApplicationJob).tap{ |c| c.include unit_module }
    end
  end

  class ReceiverInitTests < ReceiverTests
    desc "when init"
    subject{ receiver_class.new }

    setup do
      @subscriptions_dispatch_calls = []
      Assert.stub_on_call(MuchRailsPubSub.subscriptions, :dispatch) do |call|
        @subscriptions_dispatch_calls << call
      end
    end

    let(:publish_params) do
      {
        "event_name" => event_name,
        "event_params" => event_params,
      }
    end

    should have_imeth :perform

    should "dispatch the subscriptions for the given event name with params" do
      subject.perform(publish_params)

      assert_that(@subscriptions_dispatch_calls.size).equals(1)
      assert_that(@subscriptions_dispatch_calls.last.args)
        .equals([publish_params])
    end
  end
end
