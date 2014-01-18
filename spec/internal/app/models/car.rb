class Car < ActiveRecord::Base
  belongs_to :manufacturer

  after_save ThinkingSphinx::RealTime.callback_for(:car)
end
