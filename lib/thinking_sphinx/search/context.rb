# frozen_string_literal: true

class ThinkingSphinx::Search::Context
  attr_reader :search, :configuration

  def initialize(search, configuration = nil)
    @search        = search
    @configuration = configuration || ThinkingSphinx::Configuration.instance
    @memory        = {
      :raw     => [],
      :results => [],
      :panes   => ThinkingSphinx::Configuration::Defaults::PANES.clone
    }
  end

  def [](key)
    @memory[key]
  end

  def []=(key, value)
    @memory[key] = value
  end

  def marshal_dump
    [@memory.except(:raw, :indices)]
  end

  def marshal_load(array)
    @memory = array.first
  end
end
