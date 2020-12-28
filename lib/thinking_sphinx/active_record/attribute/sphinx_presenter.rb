# frozen_string_literal: true

class ThinkingSphinx::ActiveRecord::Attribute::SphinxPresenter
  SPHINX_TYPES = {
    :integer   => :uint,
    :boolean   => :bool,
    :timestamp => :uint,
    :float     => :float,
    :string    => :string,
    :bigint    => :bigint,
    :ordinal   => :str2ordinal,
    :wordcount => :str2wordcount,
    :json      => :json
  }

  def initialize(attribute, source)
    @attribute, @source = attribute, source
  end

  def collection_type
    @attribute.multi? ? :multi : sphinx_type
  end

  def declaration
    if @attribute.multi?
      multi_declaration
    else
      @attribute.name
    end
  end

  def sphinx_type
    SPHINX_TYPES[@attribute.type]
  end

  private

  def multi_declaration
    case @attribute.source_type
    when :query, :ranged_query
      query
    else
      "#{sphinx_type} #{@attribute.name} from field"
    end
  end

  def query
    ThinkingSphinx::ActiveRecord::PropertyQuery.new(
      @attribute, @source, sphinx_type
    ).to_s
  end
end
