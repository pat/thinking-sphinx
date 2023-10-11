# frozen_string_literal: true

class ThinkingSphinx::ActiveRecord::LogSubscriber < ActiveSupport::LogSubscriber
  def guard(event)
    identifier = colored_text "Sphinx"
    warn "  #{identifier}  #{event.payload[:guard]}"
  end

  def message(event)
    identifier = colored_text "Sphinx"
    debug "  #{identifier}  #{event.payload[:message]}"
  end

  def query(event)
    identifier = colored_text("Sphinx Query (%.1fms)" % event.duration)
    debug "  #{identifier}  #{event.payload[:query]}"
  end

  def caution(event)
    identifier = colored_text "Sphinx"
    warn "  #{identifier}  #{event.payload[:caution]}"
  end

  private

  if Rails.gem_version >= Gem::Version.new("7.1.0")
    def colored_text(text)
      color text, GREEN, bold: true
    end
  else
    def colored_text(text)
      color text, GREEN, true
    end
  end
end

ThinkingSphinx::ActiveRecord::LogSubscriber.attach_to :thinking_sphinx
