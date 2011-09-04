module ThinkingSphinx::ActiveRecord::Base
  def search(query = nil)
    ThinkingSphinx::Search.new query, scoped_sphinx_options
  end

  def primary_key_for_sphinx
    @primary_key_for_sphinx ||
    (
      superclass.respond_to?(:primary_key_for_sphinx?) &&
      superclass.primary_key_for_sphinx? &&
      superclass.primary_key_for_sphinx
    ) || primary_key
  end

  def primary_key_for_sphinx?
    @primary_key_for_sphinx.present?
  end

  def set_primary_key_for_sphinx(key)
    @primary_key_for_sphinx = key
  end

  private

  def scoped_sphinx_options
    {:classes => [self]}
  end
end
