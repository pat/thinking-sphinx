require "#{File.dirname(__FILE__)}/tag"
require "#{File.dirname(__FILE__)}/tagging"

class Developer < ActiveRecord::Base
  has_many :taggings, :as => :taggable
  has_many :tags, :through => :taggings
  
  define_index do
    indexes country,                      :facet => true
    indexes state,                        :facet => true
    indexes tags.text,  :as => :tags,     :facet => true
    
    has age,                              :facet => true
    has tags(:id),      :as => :tag_ids,  :facet => true
    
    facet "LOWER(city)", :as => :city, :type => :string, :value => :city
  end
end
