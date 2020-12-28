# frozen_string_literal: true

class Colour < ActiveRecord::Base
  has_many :tees

  ThinkingSphinx::Callbacks.append(self, behaviours: [:sql, :deltas])
end
