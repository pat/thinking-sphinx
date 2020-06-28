# frozen_string_literal: true

class Car < ActiveRecord::Base
  belongs_to :manufacturer

  ThinkingSphinx::Callbacks.append(self, :behaviours => [:real_time])
end
