# frozen_string_literal: true

class Bird < Animal
  ThinkingSphinx::Callbacks.append(self, :behaviours => [:sql])
end
