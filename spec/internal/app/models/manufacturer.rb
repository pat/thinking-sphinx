# frozen_string_literal: true

class Manufacturer < ActiveRecord::Base
  has_many :cars
end
