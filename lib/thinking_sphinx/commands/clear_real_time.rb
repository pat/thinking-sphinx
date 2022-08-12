# frozen_string_literal: true

class ThinkingSphinx::Commands::ClearRealTime < ThinkingSphinx::Commands::Base
  def call
    options[:indices].each do |index|
      index.render
      Dir["#{index.path}.*"].each { |path| FileUtils.rm path }
    end

    FileUtils.rm_r(binlog_path) if File.exist?(binlog_path)
  end

  private

  def binlog_path
    configuration.searchd.binlog_path
  end

  def type
    'clear_realtime'
  end
end
