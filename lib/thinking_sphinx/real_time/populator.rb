# frozen_string_literal: true

class ThinkingSphinx::RealTime::Populator
  def self.populate(index)
    new(index).populate
  end

  def initialize(index)
    @index = index
  end

  def populate(&block)
    instrument 'start_populating'

    scope.find_in_batches(:batch_size => batch_size) do |instances|
      transcriber.copy *instances
      instrument 'populated', :instances => instances
    end

    instrument 'finish_populating'
  end

  private

  attr_reader :index

  delegate :controller, :batch_size, :to => :configuration
  delegate :scope,                   :to => :index

  def configuration
    ThinkingSphinx::Configuration.instance
  end

  def instrument(message, options = {})
    ActiveSupport::Notifications.instrument(
      "#{message}.thinking_sphinx.real_time", options.merge(:index => index)
    )
  end

  def transcriber
    @transcriber ||= ThinkingSphinx::RealTime::Transcriber.new index
  end
end
