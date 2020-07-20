# frozen_string_literal: true

class City < ActiveRecord::Base
  ThinkingSphinx::Callbacks.append(self, :behaviours => [:sql])

  scope :ordered, lambda { order(:name) }
end
