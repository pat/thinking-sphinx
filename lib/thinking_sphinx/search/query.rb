# encoding: utf-8
# frozen_string_literal: true

class ThinkingSphinx::Search::Query
  attr_reader :keywords, :conditions, :star

  def initialize(keywords = '', conditions = {}, star = false)
    @keywords, @conditions, @star = keywords, conditions, star
  end

  def to_s
    (star_keyword(keywords || '') + ' ' + conditions.keys.collect { |key|
       next if conditions[key].blank?

      "#{expand_key key} #{star_keyword conditions[key], key}"
    }.join(' ')).strip
  end

  private

  def expand_key(key)
    return "@#{key}" unless key.is_a?(Array)

    "@(#{key.join(',')})"
  end

  def star_keyword(keyword, key = nil)
    return keyword.to_s unless star
    return keyword.to_s if key.to_s == 'sphinx_internal_class_name'

    ThinkingSphinx::Query.wildcard keyword, star
  end
end
