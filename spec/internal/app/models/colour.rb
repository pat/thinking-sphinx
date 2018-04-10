# frozen_string_literal: true

class Colour < ActiveRecord::Base
  has_many :tees
end
