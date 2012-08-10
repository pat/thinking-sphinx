# encoding: UTF-8
require 'stringio'

class Riddle::Configuration::Parser
  SOURCE_CLASSES = {
    'mysql'    => Riddle::Configuration::SQLSource,
    'pgsql'    => Riddle::Configuration::SQLSource,
    'mssql'    => Riddle::Configuration::SQLSource,
    'xmlpipe'  => Riddle::Configuration::XMLSource,
    'xmlpipe2' => Riddle::Configuration::XMLSource,
    'odbc'     => Riddle::Configuration::SQLSource
  }

  INDEX_CLASSES = {
    'plain'       => Riddle::Configuration::Index,
    'distributed' => Riddle::Configuration::DistributedIndex,
    'rt'          => Riddle::Configuration::RealtimeIndex
  }

  def initialize(input)
    @input   = input
  end

  def parse!
    set_indexer
    set_searchd
    set_sources
    set_indices

    configuration
  end

  private

  def inner
    @inner ||= InnerParser.new(@input).parse!
  end

  def configuration
    @configuration ||= Riddle::Configuration.new
  end

  def sources
    @sources ||= {}
  end

  def each_with_prefix(prefix)
    inner.keys.select { |key| key[/^#{prefix}\s+/] }.each do |key|
      yield key.gsub(/^#{prefix}\s+/, ''), inner[key]
    end
  end

  def set_indexer
    set_settings configuration.indexer, inner['indexer']
  end

  def set_searchd
    set_settings configuration.searchd, inner['searchd']
  end

  def set_sources
    each_with_prefix 'source' do |name, settings|
      names         = name.split(/\s*:\s*/)
      type          = settings.delete('type').first
      source        = SOURCE_CLASSES[type].new names.first, type
      source.parent = names.last if names.length > 1

      set_settings source, settings

      sources[source.name] = source
    end
  end

  def set_indices
    each_with_prefix 'index' do |name, settings|
      names        = name.split(/\s*:\s*/)
      type         = (settings.delete('type') || ['plain']).first
      index        = INDEX_CLASSES[type].new names.first
      index.parent = names.last if names.length > 1

      (settings.delete('source') || []).each do |source_name|
        index.sources << sources[source_name]
      end

      set_settings index, settings

      configuration.indices << index
    end
  end

  def set_settings(object, hash)
    hash.each do |key, values|
      values.each do |value|
        set_setting object, key, value
      end
    end
  end

  def set_setting(object, key, value)
    if object.send(key).is_a?(Array)
      object.send(key) << value
    else
      object.send "#{key}=", value
    end
  end

  class InnerParser
    SETTING_PATTERN = /^(\w+)\s*=\s*(.*)$/

    def initialize(input)
      @stream   = StringIO.new(input)
      @sections = {}
    end

    def parse!
      while label = next_line do
        @sections[label] = next_settings
      end

      @sections
    end

    private

    def next_line
      line = @stream.gets
      return line if line.nil?

      line = line.strip
      line.empty? ? next_line : line
    end

    def next_settings
      settings = Hash.new { |hash, key| hash[key] = [] }
      line = ''
      while line.empty? || line == '{' do
        line = next_line
      end

      while line != '}' do
        begin
          key, value = *SETTING_PATTERN.match(line).captures
          settings[key] << value
          while value[/\\$/] do
            value = next_line
            settings[key].last << "\n" << value
          end
        rescue => error
          raise error, "Error handling line '#{line}': #{error.message}",
            error.backtrace
        end

        line = next_line
      end

      settings
    end
  end
end
