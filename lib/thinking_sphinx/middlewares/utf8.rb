class ThinkingSphinx::Middlewares::UTF8 <
  ThinkingSphinx::Middlewares::Middleware

  def call(contexts)
    contexts.each do |context|
      context[:results].each { |row| update_row row }
    end

    app.call contexts
  end

  private

  def update_row(row)
    row.each do |key, value|
      next unless value.is_a?(String)

      value.encode!("ISO-8859-1")
      row[key] = value.force_encoding("UTF-8")
    end
  end
end
