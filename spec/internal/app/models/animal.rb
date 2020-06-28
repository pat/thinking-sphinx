# frozen_string_literal: true

class Animal < ActiveRecord::Base
  ThinkingSphinx::Callbacks.append(self, :behaviours => [:sql])
end
