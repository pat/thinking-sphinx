# frozen_string_literal: true

class ThinkingSphinx::Middlewares::UTF8 <
  ThinkingSphinx::Middlewares::Middleware

  def call(contexts)
    contexts.each do |context|
      context[:results].each { |row| update_row row }
      update_row context[:meta]
    end unless encoded?

    app.call contexts
  end

  private

  def encoded?
    ThinkingSphinx::Configuration.instance.settings['utf8'].nil? ||
    ThinkingSphinx::Configuration.instance.settings['utf8']
  end

  def update_row(row)
    row.each do |key, value|
      next unless value.is_a?(String)

      row[key] = ThinkingSphinx::UTF8.encode value
    end
  end
end
