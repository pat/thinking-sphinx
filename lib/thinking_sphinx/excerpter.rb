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
    result = ThinkingSphinx::Connection.take do |connection|
      connection.execute(statement_for(text)).first['snippet']
    end

    ThinkingSphinx::Configuration.instance.settings['utf8'] ? result :
      ThinkingSphinx::UTF8.encode(result)
  end

  private

  def statement_for(text)
    Riddle::Query.snippets(text, index, words, options)
  end
end
