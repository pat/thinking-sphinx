# frozen_string_literal: true

class Event < ActiveRecord::Base
  belongs_to :eventable, :polymorphic => true
end
