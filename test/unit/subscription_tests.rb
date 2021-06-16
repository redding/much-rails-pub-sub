# frozen_string_literal: true

require "assert"
require "much-rails-pub-sub/subscription"

class MuchRailsPubSub::Subscription
  class UnitTests < Assert::Context
    desc "MuchRailsPubSub::Subscription"
    subject{ unit_class }

    let(:unit_class){ MuchRailsPubSub::Subscription }

    let(:event_name){ "something_happened_v1" }
    let(:event_params){ { some: "thing" } }

    should "complain if initialized with an invalid job class" do
      assert_that{ subject.new(event_name, job_class: Class.new) }
        .raises(ArgumentError)
    end
  end

  class InitTests < UnitTests
    desc "when init"
    subject{ unit_class.new(event_name, job_class: fake_job_class) }

    let(:fake_job_class){ FakeJobClass.new }

    should have_readers :event_name, :job_class

    should "call #perform_later on the configured subscription job class" do
      subject.call(event_params)

      assert_that(fake_job_class.perform_calls.size).equals(1)
      assert_that(fake_job_class.perform_calls.last.args)
        .equals([event_params])
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
