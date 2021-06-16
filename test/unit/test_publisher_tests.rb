# frozen_string_literal: true

require "assert"
require "much-rails-pub-sub/test_publisher"

class MuchRailsPubSub::TestPublisher
  class UnitTests < Assert::Context
    desc "MuchRailsPubSub::TestPublisher"
    subject{ unit_class }

    setup do
      Assert.stub(MuchRailsPubSub.config, :publish_job_class) do
        fake_publish_job_class
      end
    end

    let(:unit_class){ MuchRailsPubSub::TestPublisher }

    let(:event_name){ "something_happened_v1" }
    let(:event_params){ { some: "thing" } }
    let(:fake_publish_job_class){ FakeJobClass.new }

    should "be configured as expected" do
      assert_that(subject < MuchRailsPubSub::Publisher).is_true
    end

    should "doesnn't call #perform_later on the configured publish job class" do
      event = subject.call(event_name, event_params: event_params)
      assert_that(event).is_a?(MuchRailsPubSub::Event)

      assert_that(fake_publish_job_class.perform_calls.size).equals(0)
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
end
