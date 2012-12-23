class ThinkingSphinx::RealTime::Field < ThinkingSphinx::RealTime::Property
  include ThinkingSphinx::Core::Field

  def translate(object)
    Array(super || '').join(' ').gsub(/\s+/, ' ')
  end
end
