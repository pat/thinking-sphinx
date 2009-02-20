class GenericDeltaHandler < ThinkingSphinx::Deltas::DefaultDelta
  
  def index(model, instance = nil)
    #do nothing but set a bit for every record 
    #this is just a demonstration of extensibility
    model.update_all(:changed_by_generic => true)
  end
end