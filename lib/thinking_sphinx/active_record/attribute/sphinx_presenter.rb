class ThinkingSphinx::ActiveRecord::Attribute::SphinxPresenter
  SPHINX_TYPES = {
    :integer   => :uint,
    :boolean   => :bool,
    :timestamp => :timestamp,
    :float     => :float,
    :string    => :string,
    :bigint    => :bigint,
    :ordinal   => :str2ordinal,
    :wordcount => :str2wordcount
  }

  def initialize(attribute)
    @attribute = attribute
  end

  def collection_type
    @attribute.multi? ? :multi : sphinx_type
  end

  def declaration
    if @attribute.multi?
      "#{sphinx_type} #{@attribute.name} from field"
    else
      @attribute.name
    end
  end

  def sphinx_type
    SPHINX_TYPES[@attribute.type]
  end
end
