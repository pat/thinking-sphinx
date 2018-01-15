# frozen_string_literal: true

class ThinkingSphinx::Interfaces::RealTime < ThinkingSphinx::Interfaces::Base
  def initialize(configuration, options, stream = STDOUT)
    super

    configuration.preload_indices

    command :prepare
  end

  def clear
    command :clear_real_time, :indices => indices
  end

  def index
    return if indices.empty?
    if !command :running
      stream.puts <<-TXT
The Sphinx daemon is not currently running. Real-time indices can only be
populated by sending commands to a running daemon.
      TXT
      return
    end

    command :index_real_time, :indices => indices
  end

  private

  def index_names
    @index_names ||= options[:index_names] || []
  end

  def indices
    @indices ||= begin
      indices = configuration.indices.select { |index| index.type == 'rt' }

      if index_names.any?
        indices.select! { |index| index_names.include? index.name }
      end

      indices
    end
  end
end
