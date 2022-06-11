# frozen_string_literal: true

class ThinkingSphinx::ActiveRecord::Callbacks::DeleteCallbacks <
  ThinkingSphinx::Callbacks

  callbacks :after_commit, :after_destroy, :after_rollback

  def after_commit
    delete_from_sphinx
  end

  def after_destroy
    delete_from_sphinx
  end

  def after_rollback
    delete_from_sphinx
  end

  private

  def delete_from_sphinx
    return if ThinkingSphinx::Callbacks.suspended?

    ThinkingSphinx::Processor.new(instance: instance).delete
  end
end
