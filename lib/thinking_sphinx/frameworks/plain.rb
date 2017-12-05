# frozen_string_literal: true

class ThinkingSphinx::Frameworks::Plain
  attr_accessor :environment, :root

  def initialize
    @environment = 'production'
    @root        = Dir.pwd
  end
end
