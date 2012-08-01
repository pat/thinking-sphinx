class ThinkingSphinx::Search::Glaze < BlankSlate
  def initialize(context, object, raw = {}, pane_classes = [])
    @object, @raw = object, raw

    @panes = pane_classes.collect { |klass|
      klass.new context, object, @raw
    }
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

  private

  def method_missing(method, *args, &block)
    if @object.respond_to?(method)
      @object.send(method, *args, &block)
    else
      pane = @panes.detect { |pane| pane.respond_to?(method) }
      pane.nil? ? super : pane.send(method, *args, &block)
    end
  end
end
