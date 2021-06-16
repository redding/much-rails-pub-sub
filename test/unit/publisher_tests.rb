# frozen_string_literal: true

require "assert"
require "much-rails-pub-sub/publisher"

class MuchRailsPubSub::Publisher
  class UnitTests < Assert::Context
    desc "MuchRailsPubSub::Publisher"
    subject{ unit_class }

    let(:unit_class){ MuchRailsPubSub::Publisher }

    let(:event_name){ "something_happened_v1" }
    let(:event_params){ { some: "thing" } }

    should "be configured as expected" do
      assert_that(subject).includes(MuchRails::CallMethod)
    end

    should "not implement its on call method" do
      assert_that{
        subject.call(event_name, event_params: event_params)
      }.raises(NotImplementedError)
    end
  end

  class InitTests < UnitTests
    desc "when init"
    subject{ unit_class.new(event_name, event_params: event_params) }

    should have_readers :event
    should have_imeths :event_id, :event_name, :event_params

    should "know its attributes" do
      assert_that(subject.event).is_a?(MuchRailsPubSub::Event)
      assert_that(subject.event.name).equals(event_name)
      assert_that(subject.event.params).equals(event_params)

      assert_that(subject.event_id).equals(subject.event.id)
      assert_that(subject.event_name).equals(subject.event.name)
      assert_that(subject.event_params).equals(subject.event.params)
    end
  end
end
