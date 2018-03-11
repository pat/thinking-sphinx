# frozen_string_literal: true

class ThinkingSphinx::Commands::MergeAndUpdate < ThinkingSphinx::Commands::Base
  def call
    configuration.preload_indices
    configuration.render

    index_pairs.each do |(core_index, delta_index)|
      command :merge,
        :core_index  => core_index,
        :delta_index => delta_index,
        :filters     => {:sphinx_deleted => 0}

      core_index.model.where(:delta => true).update_all(:delta => false)
    end
  end

  private

  delegate :controller, :to => :configuration

  def core_indices
    indices.select { |index| !index.delta? }.select do |index|
      name_filters.empty? ||
      name_filters.include?(index.name.gsub(/_core$/, ''))
    end
  end

  def delta_for(core_index)
    name = core_index.name.gsub(/_core$/, "_delta")
    indices.detect { |index| index.name == name }
  end

  def index_pairs
    core_indices.collect { |core_index|
      [core_index, delta_for(core_index)]
    }
  end

  def indices
    @indices ||= configuration.indices.select { |index|
      index.type == "plain" && index.options[:delta_processor]
    }
  end

  def indices_exist?(*indices)
    indices.all? { |index| File.exist?("#{index.path}.spi") }
  end

  def name_filters
    @name_filters ||= options[:index_names] || []
  end

  def type
    'merging_and_updating'
  end
end
