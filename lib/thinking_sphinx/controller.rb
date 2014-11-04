class ThinkingSphinx::Controller < Riddle::Controller
  def index(*indices)
    options = indices.extract_options!
    indices << '--all' if indices.empty?

    ThinkingSphinx::Guard::Files.call(indices) do |names|
      super(*(names + [options]))
    end
  end
end
