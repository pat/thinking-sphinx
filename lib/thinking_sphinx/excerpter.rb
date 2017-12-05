# frozen_string_literal: true

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
      query = statement_for text
      ThinkingSphinx::Logger.log :query, query do
        connection.execute(query).first['snippet']
      end
    end

    encoded? ? result : ThinkingSphinx::UTF8.encode(result)
  end

  private

  def statement_for(text)
    Riddle::Query.snippets(text, index, words, options)
  end

  def encoded?
    ThinkingSphinx::Configuration.instance.settings['utf8'].nil? ||
    ThinkingSphinx::Configuration.instance.settings['utf8']
  end
end
