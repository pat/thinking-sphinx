class ThinkingSphinx::AttributeTypes
  def self.call
    @call ||= new.call
  end

  def self.reset
    @call = nil
  end

  def call
    return {} unless File.exist?(configuration_file)

    realtime_indices.each { |index|
      map_types_with_prefix index, :rt,
        [:uint, :bigint, :float, :timestamp, :string, :bool, :json]

      index.rt_attr_multi.each     { |name| attributes[name] << :uint }
      index.rt_attr_multi_64.each  { |name| attributes[name] << :bigint }
    }

    plain_sources.each { |source|
      map_types_with_prefix source, :sql,
        [:uint, :bigint, :float, :timestamp, :string, :bool, :json]

      source.sql_attr_str2ordinal    { |name| attributes[name] << :uint }
      source.sql_attr_str2wordcount  { |name| attributes[name] << :uint }
      source.sql_attr_multi.each { |setting|
        type, name, *ignored = setting.split(/\s+/)
        attributes[name] << type.to_sym
      }
    }

    attributes.values.each &:uniq!
    attributes
  end

  private

  def attributes
    @attributes ||= Hash.new { |hash, key| hash[key] = [] }
  end

  def configuration
    @configuration ||= Riddle::Configuration.parse!(
      File.read(configuration_file)
    )
  end

  def configuration_file
    ThinkingSphinx::Configuration.instance.configuration_file
  end

  def map_types_with_prefix(object, prefix, types)
    types.each do |type|
      object.public_send("#{prefix}_attr_#{type}").each do |name|
        attributes[name] << type
      end
    end
  end

  def plain_sources
    configuration.indices.select { |index|
      index.type == 'plain' || index.type.nil?
    }.collect(&:sources).flatten
  end

  def realtime_indices
    configuration.indices.select { |index| index.type == 'rt' }
  end
end
