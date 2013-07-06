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
    @words = @options.delete(:words) if @options[:words]
  end

  def excerpt!(text)
    result = connection.query(statement_for(text)).first['snippet']

    result.encode!("ISO-8859-1")
    result.force_encoding("UTF-8")
  end

  private

  def connection
    @connection ||= ThinkingSphinx::Connection.new
  end

  def statement_for(text)
    Riddle::Query.snippets(text, index, words, options)
  end
end
