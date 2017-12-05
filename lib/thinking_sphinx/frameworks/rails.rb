# frozen_string_literal: true

class ThinkingSphinx::Frameworks::Rails
  def environment
    Rails.env
  end

  def root
    Rails.root
  end
end
