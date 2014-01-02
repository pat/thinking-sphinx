# encoding: utf-8

class ThinkingSphinx::Search::Query
  DEFAULT_TOKEN = /[\p{Word}\\][\p{Word}\\@]+/

  attr_reader :keywords, :conditions, :star

  def initialize(keywords = '', conditions = {}, star = false)
    @keywords, @conditions, @star = keywords, conditions, star
  end

  def to_s
    (star_keyword(keywords || '') + ' ' + conditions.keys.collect { |key|
       next if conditions[key].blank?

      "@#{key} #{star_keyword conditions[key], key}"
    }.join(' ')).strip
  end

  private

  def star_keyword(keyword, key = nil)
    unless star && (key.nil? || key.to_s != 'sphinx_internal_class_name')
      return keyword.to_s
    end

    token = star.is_a?(Regexp) ? star : DEFAULT_TOKEN
    keyword.gsub(/("#{token}(.*?#{token})?"|(?![!-])#{token})/u) do
      pre, proper, post = $`, $&, $'
      # E.g. "@foo", "/2", "~3", but not as part of a token
      is_operator = pre.match(%r{\A(\W|^)[@~/]\Z}) ||
                    pre.match(%r{(\W|^)@\([^\)]*$})
      # E.g. "foo bar", with quotes
      is_quote    = proper[/^".*"$/]
      has_star    = post[/\*$/] || pre[/^\*/]
      if is_operator || is_quote || has_star
        proper
      else
        "*#{proper}*"
      end
    end
  end
end
