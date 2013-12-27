class ThinkingSphinx::Wildcard
  DEFAULT_TOKEN = /[\p{Word}\\][\p{Word}\\@]+[\p{Word}]/

  def self.call(query, pattern = DEFAULT_TOKEN)
    new(query, pattern).call
  end

  def initialize(query, pattern = DEFAULT_TOKEN)
    @query   = query || ''
    @pattern = pattern.is_a?(Regexp) ? pattern : DEFAULT_TOKEN
  end

  def call
    query.gsub(/("#{pattern}(.*?#{pattern})?"|(?![!-])#{pattern})/u) do
      pre, proper, post = $`, $&, $'
      # E.g. "@foo", "/2", "~3", but not as part of a token pattern
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

  private

  attr_reader :query, :pattern
end
