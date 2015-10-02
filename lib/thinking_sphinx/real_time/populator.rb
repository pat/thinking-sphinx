class ThinkingSphinx::RealTime::Populator
  def self.populate(index)
    new(index).populate
  end

  def initialize(index)
    @index = index
  end

  def populate(&block)
    instrument 'start_populating'

    remove_files

    scope.find_in_batches do |instances|
      transcriber.copy instances
      instrument 'populated', :instance => instances
    end

    controller.rotate
    instrument 'finish_populating'
  end

  private

  attr_reader :index

  delegate :controller, :to => :configuration
  delegate :scope,      :to => :index

  def configuration
    ThinkingSphinx::Configuration.instance
  end

  def instrument(message, options = {})
    ActiveSupport::Notifications.instrument(
      "#{message}.thinking_sphinx.real_time", options.merge(:index => index)
    )
  end

  def remove_files
    Dir["#{index.path}*"].each { |file| FileUtils.rm file }
  end

  def transcriber
    @transcriber ||= ThinkingSphinx::RealTime::Transcriber.new index
  end
end
