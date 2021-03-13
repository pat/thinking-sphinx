# frozen_string_literal: true

require "pathname"

class ThinkingSphinx::Settings
  ALWAYS_ABSOLUTE = %w[ socket ]
  FILE_KEYS = %w[
    indices_location configuration_file bin_path log query_log pid_file
    binlog_path snippets_file_prefix sphinxql_state path stopwords wordforms
    exceptions global_idf rlp_context rlp_root rlp_environment plugin_dir
    lemmatizer_base mysql_ssl_cert mysql_ssl_key mysql_ssl_ca
  ].freeze
  DEFAULTS = {
    "configuration_file"       => "config/ENVIRONMENT.sphinx.conf",
    "indices_location"         => "db/sphinx/ENVIRONMENT",
    "pid_file"                 => "log/ENVIRONMENT.sphinx.pid",
    "log"                      => "log/ENVIRONMENT.searchd.log",
    "query_log"                => "log/ENVIRONMENT.searchd.query.log",
    "binlog_path"              => "tmp/binlog/ENVIRONMENT",
    "workers"                  => "threads",
    "mysql_encoding"           => "utf8",
    "maximum_statement_length" => (2 ** 23) - 5,
    "real_time_tidy"           => false
  }.freeze

  def self.call(configuration)
    new(configuration).call
  end

  def initialize(configuration)
    @configuration = configuration
  end

  def call
    return defaults unless File.exists? file

    merged.inject({}) do |hash, (key, value)|
      if absolute_key?(key)
        hash[key] = absolute value
      else
        hash[key] = value
      end
      hash
    end
  end

  private

  attr_reader :configuration

  delegate :framework, :to => :configuration

  def absolute(relative)
    return relative if relative.nil?

    real_path File.absolute_path(relative, framework.root)
  end

  def absolute_key?(key)
    return true if ALWAYS_ABSOLUTE.include?(key)

    merged["absolute_paths"] && file_keys.include?(key)
  end

  def defaults
    DEFAULTS.inject({}) do |hash, (key, value)|
      if value.is_a?(String)
        value = value.gsub("ENVIRONMENT", framework.environment)
      end

      if FILE_KEYS.include?(key)
        hash[key] = absolute value
      else
        hash[key] = value
      end

      hash
    end
  end

  def file
    @file ||= Pathname.new(framework.root).join "config", "thinking_sphinx.yml"
  end

  def file_keys
    @file_keys ||= FILE_KEYS + (original["file_keys"] || [])
  end

  def join(first, last)
    return first if last.nil?

    File.join first, last
  end

  def merged
    @merged ||= defaults.merge original
  end

  def original
    input = File.read file
    input = ERB.new(input).result if defined?(ERB)

    contents = YAML.load input
    contents && contents[framework.environment] || {}
  end

  def real_path(base, nonexistent = nil)
    if File.exist?(base)
      join File.realpath(base), nonexistent
    else
      components = File.split base
      real_path components.first, join(components.last, nonexistent)
    end
  end
end
