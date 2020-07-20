# frozen_string_literal: true

class ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks <
  ThinkingSphinx::Callbacks

  callbacks :after_destroy, :after_rollback

  def after_destroy
    delete_from_sphinx
  end

  def after_rollback
    delete_from_sphinx
  end

  private

  def delete_from_sphinx
    return if ThinkingSphinx::Callbacks.suspended? || instance.new_record?

    indices.each { |index|
      ThinkingSphinx::Deletion.perform(
        index, instance.public_send(index.primary_key)
      )
    }
  end

  def indices
    ThinkingSphinx::Configuration.instance.index_set_class.new(
      :instances => [instance], :classes => [instance.class]
    ).to_a
  end
end
