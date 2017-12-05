# frozen_string_literal: true

class ThinkingSphinx::ActiveRecord::Field <
  ThinkingSphinx::ActiveRecord::Property
  include ThinkingSphinx::Core::Field

  def file?
    options[:file]
  end

  def with_attribute?
    options[:sortable] || options[:facet]
  end

  def wordcount?
    options[:wordcount]
  end
end
