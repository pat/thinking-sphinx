# frozen_string_literal: true

class ThinkingSphinx::Commands::Merge < ThinkingSphinx::Commands::Base
  def call
    return unless indices_exist?

    controller.merge(
      options[:core_index].name,
      options[:delta_index].name,
      :filters => options[:filters],
      :verbose => options[:verbose]
    )
  end

  private

  delegate :controller, :to => :configuration

  def indices_exist?
    File.exist?("#{options[:core_index].path}.spi") &&
    File.exist?("#{options[:delta_index].path}.spi")
  end

  def type
    'merging'
  end
end
