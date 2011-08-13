class ThinkingSphinx::ActiveRecord::Index < Riddle::Configuration::Index
  attr_reader :model
  
  def initialize(model, name, *sources)
    @model = model
    name   = model.name if name.nil?
    
    super name, *sources
  end
end
