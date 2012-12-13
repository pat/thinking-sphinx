module ThinkingSphinx::Core::Field
  def infixing?
    options[:infixes]
  end

  def prefixing?
    options[:prefixes]
  end
end
