# frozen_string_literal: true

class ThinkingSphinx::Search::Glaze < BasicObject
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

  def respond_to?(method, include_private = false)
    @object.respond_to?(method, include_private) ||
    @panes.any? { |pane| pane.respond_to?(method, include_private) }
  end

  def unglazed
    @object
  end

  private

  def method_missing(method, *args, &block)
    pane = @panes.detect { |pane| pane.respond_to?(method) }
    if @object.respond_to?(method) || pane.nil?
      @object.send(method, *args, &block)
    else
      pane.send(method, *args, &block)
    end
  end
end
