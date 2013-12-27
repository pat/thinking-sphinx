class ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks <
  ThinkingSphinx::Callbacks

  callbacks :after_destroy

  def after_destroy
    return if instance.new_record?

    indices.each { |index|
      ThinkingSphinx::Deletion.perform index, instance.id
    }
  end

  private

  def indices
    ThinkingSphinx::IndexSet.new([instance.class], []).to_a
  end
end
