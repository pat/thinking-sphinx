# frozen_string_literal: true

class ThinkingSphinx::RakeInterface
  DEFAULT_OPTIONS = {:verbose => true}

  def initialize(options = {})
    @options           = DEFAULT_OPTIONS.merge options
    @options[:verbose] = false if @options[:silent]
  end

  def configure
    ThinkingSphinx::Commander.call :configure, configuration, options
  end

  def daemon
    @daemon ||= ThinkingSphinx::Interfaces::Daemon.new configuration, options
  end

  def rt
    @rt ||= ThinkingSphinx::Interfaces::RealTime.new configuration, options
  end

  def sql
    @sql ||= ThinkingSphinx::Interfaces::SQL.new configuration, options
  end

  private

  attr_reader :options

  def configuration
    ThinkingSphinx::Configuration.instance
  end
end
