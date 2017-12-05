# frozen_string_literal: true

class ThinkingSphinx::Panes::AttributesPane
  def initialize(context, object, raw)
    @raw = raw
  end

  def sphinx_attributes
    @raw
  end
end
