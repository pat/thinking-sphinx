# frozen_string_literal: true

class ThinkingSphinx::Commands::IndexRealTime < ThinkingSphinx::Commands::Base
  def call
    options[:indices].each do |index|
      ThinkingSphinx::RealTime::Populator.populate index

      command :rotate
    end
  end

  private

  def type
    'indexing'
  end
end
