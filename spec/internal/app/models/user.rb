# frozen_string_literal: true

class User < ActiveRecord::Base
  has_many :articles

  default_scope { order(:id) }
  scope :recent, lambda { where('created_at > ?', 1.week.ago) }
end
