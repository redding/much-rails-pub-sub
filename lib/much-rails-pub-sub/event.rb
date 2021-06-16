# frozen_string_literal: true

require "much-rails-pub-sub"

MuchRailsPubSub::Event =
  Struct.new(:id, :name, :params) do
    def initialize(name, params:)
      super(SecureRandom.uuid, name, params)
    end
  end
