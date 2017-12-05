# frozen_string_literal: true

class Tag < ActiveRecord::Base
  has_many :taggings
  has_many :articles, :through => :taggings
end
