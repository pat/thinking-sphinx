# frozen_string_literal: true

class Tee < ActiveRecord::Base
  belongs_to :colour

  ThinkingSphinx::Callbacks.append(self, :behaviours => [:sql])
  ThinkingSphinx::Callbacks.append(
    self, behaviours: [:sql, :deltas], :path => [:colour]
  )
end
