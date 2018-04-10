# frozen_string_literal: true

class ThinkingSphinx::Logger
  def self.log(notification, message, &block)
    ActiveSupport::Notifications.instrument(
      "#{notification}.thinking_sphinx", notification => message, &block
    )
  end
end
