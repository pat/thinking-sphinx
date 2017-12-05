# frozen_string_literal: true

class Album < ActiveRecord::Base
  self.primary_key = :id

  before_validation :set_id, :on => :create
  before_validation :set_integer_id, :on => :create

  validates :id,         :presence => true, :uniqueness => true
  validates :integer_id, :presence => true, :uniqueness => true

  private

  def set_id
    self.id = (Album.maximum(:id) || "a").next
  end

  def set_integer_id
    self.integer_id = (Album.maximum(:integer_id) || 0) + 1
  end
end
