class ThinkingSphinx::Search::Glaze < BlankSlate
  def initialize(object, raw = {})
    @object, @raw = object, raw.with_indifferent_access
  end

  def ==(object)
    (@object == object) || super
  end

  def equal?(object)
    @object.equal? object
  end

  def unglazed
    @object
  end

  def sphinx_attributes
    if @object.respond_to?(:sphinx_attributes)
      @object.sphinx_attributes
    else
      @raw
    end
  end

  private

  def method_missing(method, *args, &block)
    @object.send(method, *args, &block)
  end
end
