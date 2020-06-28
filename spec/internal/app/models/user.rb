# frozen_string_literal: true

class User < ActiveRecord::Base
  has_many :articles

  ThinkingSphinx::Callbacks.append(self, :behaviours => [:sql])

  default_scope { order(:id) }
  scope :recent, lambda { where('created_at > ?', 1.week.ago) }
end
