class ThinkingSphinx::ActiveRecord::AttributeSphinxPresenter
  def initialize(attribute, type)
    @attribute, @type = attribute, type
  end

  def declaration
    if @type.multi?
      "#{@type.sphinx_type} #{@attribute.name} from field"
    else
      @attribute.name
    end
  end
end
