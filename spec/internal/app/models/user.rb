class User < ActiveRecord::Base
  has_many :articles
end