class ThinkingSphinx::UTF8
  attr_reader :string

  def self.encode(string)
    new(string).encode
  end

  def initialize(string)
    @string = string
  end

  def encode
    string.encode!('ISO-8859-1')
    string.force_encoding('UTF-8')
  end
end
