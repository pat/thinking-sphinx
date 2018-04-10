# frozen_string_literal: true

class ThinkingSphinx::Hooks::GuardPresence
  def self.call(configuration = nil, stream = STDERR)
    new(configuration, stream).call
  end

  def initialize(configuration = nil, stream = STDERR)
    @configuration = configuration || ThinkingSphinx::Configuration.instance
    @stream        = stream
  end

  def call
    return if files.empty?

    stream.puts "WARNING: The following indexing guard files exist:"
    files.each do |file|
      stream.puts " * #{file}"
    end
    stream.puts <<-TXT
These files indicate indexing is already happening. If that is not the case,
these files should be deleted to ensure all indices can be processed.

    TXT
  end

  private

  attr_reader :configuration, :stream

  def files
    @files ||= Dir["#{configuration.indices_location}/ts-*.tmp"]
  end
end
