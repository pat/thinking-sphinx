# frozen_string_literal: true

class Tee < ActiveRecord::Base
  belongs_to :colour

  ThinkingSphinx::Callbacks.append(self, :behaviours => [:sql])
end
