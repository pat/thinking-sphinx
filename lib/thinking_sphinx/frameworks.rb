# frozen_string_literal: true

module ThinkingSphinx::Frameworks
  def self.current
    defined?(::Rails) ? ThinkingSphinx::Frameworks::Rails.new :
      ThinkingSphinx::Frameworks::Plain.new
  end
end

require 'thinking_sphinx/frameworks/plain'
require 'thinking_sphinx/frameworks/rails'
