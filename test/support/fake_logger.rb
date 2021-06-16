# frozen_string_literal: true

class FakeLogger
  UNKNOWN = ::Logger::UNKNOWN # 5
  WARN = ::Logger::WARN # 2
  DEBUG = ::Logger::DEBUG # 0

  attr_reader :info_calls, :warning_calls, :error_calls, :debug_calls
  attr_accessor :level

  def initialize(level: DEBUG)
    @level = level
    @info_calls = []
    @warning_calls = []
    @error_calls = []
    @debug_calls = []
  end

  def info(*args)
    @info_calls << args
  end

  def warning(*args)
    @warning_calls << args
  end

  def error(*args)
    @error_calls << args
  end

  def debug(*args)
    @debug_calls << args
  end
end
