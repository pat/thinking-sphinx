class ThinkingSphinx::ActiveRecord::Index < Riddle::Configuration::Index
  include ThinkingSphinx::Core::Index

  attr_reader :reference
  attr_writer :definition_block

  def append_source
    ThinkingSphinx::ActiveRecord::SQLSource.new(
      model, source_options
    ).tap do |source|
      sources << source
    end
  end

  def delta?
    @options[:delta?]
  end

  def delta_processor
    @options[:delta_processor].try(:new, adapter)
  end

  def facets
    @facets ||= sources.collect(&:facets).flatten
  end

  def unique_attribute_names
    sources.collect(&:attributes).flatten.collect(&:name)
  end

  private

  def adapter
    @adapter ||= ThinkingSphinx::ActiveRecord::DatabaseAdapters.
      adapter_for(model)
  end

  def interpreter
    ThinkingSphinx::ActiveRecord::Interpreter
  end

  def name_suffix
    @options[:delta?] ? 'delta' : 'core'
  end

  def source_options
    {
      :name            => name,
      :offset          => offset,
      :delta?          => @options[:delta?],
      :delta_processor => @options[:delta_processor],
      :primary_key     => @options[:primary_key] || model.primary_key || :id
    }
  end
end
