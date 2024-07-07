# frozen_string_literal: true

class ThinkingSphinx::Commands::ClearSQL < ThinkingSphinx::Commands::Base
  def call
    options[:indices].each do |index|
      index.render
      Dir["#{index.path}.*"].each { |path| FileUtils.rm path }
    end

    FileUtils.rm_rf Dir["#{configuration.indices_location}/ts-*.tmp"]
  end

  private

  def type
    'clear_sql'
  end
end
