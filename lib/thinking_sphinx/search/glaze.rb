class ThinkingSphinx::Search::Glaze < BlankSlate
  def initialize(object)
    @object = object
  end

  def ==(object)
    (@object == object) || super
  end

  def equal?(object)
    @object.equal? object
  end

  def !=(object)
    @object != object
  end

  def unglazed
    @object
  end

  private

  def method_missing(method, *args, &block)
    @object.send(method, *args, &block)
  end
end
