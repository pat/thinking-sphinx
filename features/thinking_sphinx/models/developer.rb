require 'features/thinking_sphinx/models/tag'
require 'features/thinking_sphinx/models/tagging'

class Developer < ActiveRecord::Base
  has_many :taggings, :as => :taggable
  has_many :tags, :through => :taggings
  
  define_index do
    indexes country,                      :facet => true
    indexes state,                        :facet => true
    indexes tags.text,  :as => :tags,     :facet => true
    has age,                              :facet => true
    has tags(:id),      :as => :tag_ids,  :facet => true
    facet city
  end
end
