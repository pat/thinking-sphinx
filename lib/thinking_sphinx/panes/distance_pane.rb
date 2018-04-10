# frozen_string_literal: true

class ThinkingSphinx::Panes::DistancePane
  def initialize(context, object, raw)
    @raw = raw
  end

  def distance
    @raw['geodist'].to_f
  end

  def geodist
    @raw['geodist'].to_f
  end
end
