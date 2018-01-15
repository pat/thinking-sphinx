# frozen_string_literal: true

class ThinkingSphinx::Commands::Merge < ThinkingSphinx::Commands::Base
  def call
    configuration.preload_indices
    configuration.render

    index_pairs.each do |(core_index, delta_index)|
      next unless indices_exist? core_index, delta_index

      controller.merge core_index.name, delta_index.name,
        :filters => {:sphinx_deleted => 0},
        :verbose => options[:verbose]

      core_index.model.where(:delta => true).update_all(:delta => false)
    end
  end

  private

  delegate :controller, :to => :configuration

  def delta_for(core_index)
    indices.detect do |index|
      index.name = core_index.name.gsub(/_core$/, "_delta")
    end
  end

  def index_pairs
    indices.select { |index| !index.delta? }.collect { |core_index|
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

  def type
    'merging'
  end
end
