# frozen_string_literal: true

require "pathname"

class ThinkingSphinx::Settings
  FILE_KEYS = %w[
    indices_location configuration_file bin_path log query_log pid_file
    binlog_path snippets_file_prefix sphinxql_state path stopwords wordforms
    exceptions global_idf rlp_context rlp_root rlp_environment plugin_dir
    lemmatizer_base mysql_ssl_cert mysql_ssl_key mysql_ssl_ca
  ].freeze

  def self.call(configuration)
    new(configuration).call
  end

  def initialize(configuration)
    @configuration = configuration
  end

  def call
    return {} unless File.exists? file
    return original unless original["absolute_paths"]

    original.inject({}) do |hash, (key, value)|
      if file_keys.include?(key)
        hash[key] = File.absolute_path value, framework.root
      else
        hash[key] = value
      end
      hash
    end
  end

  private

  attr_reader :configuration

  delegate :framework, :to => :configuration

  def file
    @file ||= Pathname.new(framework.root).join "config", "thinking_sphinx.yml"
  end

  def file_keys
    @file_keys ||= FILE_KEYS + (original["file_keys"] || [])
  end

  def original
    @original ||= begin
      input = File.read file
      input = ERB.new(input).result if defined?(ERB)

      contents = YAML.load input
      contents && contents[framework.environment] || {}
    end
  end
end
