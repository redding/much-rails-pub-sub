# frozen_string_literal: true

require "assert"
require "much-rails-pub-sub/event"

class MuchRailsPubSub::Event
  class UnitTests < Assert::Context
    desc "MuchRailsPubSub::Event"
    subject{ unit_class }

    let(:unit_class){ MuchRailsPubSub::Event }

    let(:event_id){ Factory.uuid }
    let(:event_name){ "something_happened_v1" }
    let(:event_params){ { some: "thing" } }
  end

  class InitTests < UnitTests
    desc "when init"
    subject{ unit_class.new(event_name, params: event_params) }

    setup do
      event_id
      Assert.stub(SecureRandom, :uuid){ event_id }
    end

    should have_imeths :id, :name, :params

    should "know its attributes" do
      assert_that(subject.id).equals(event_id)
      assert_that(subject.name).equals(event_name)
      assert_that(subject.params).equals(event_params)
    end
  end
end
