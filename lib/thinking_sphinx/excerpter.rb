class ThinkingSphinx::Excerpter
  DefaultOptions = {
    :before_match    => '<span class="match">',
    :after_match     => '</span>',
    :chunk_separator => ' &#8230; ' # ellipsis
  }

  attr_accessor :index, :words, :options

  def initialize(index, words, options = {})
    @index, @words = index, words
    @options = DefaultOptions.merge(options)
  end

  def excerpt!(text)
    connection.query(Riddle::Query.snippets(text, index, words, options)).
      first['snippet']
  end

  private

  def connection
    @connection ||= ThinkingSphinx::Configuration.instance.connection
  end
end
