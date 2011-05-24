class Post < ActiveRecord::Base
  has_many :comments, :dependent => :destroy
  has_many :taggings, :as => :taggable
  has_many :tags, :through => :taggings
  belongs_to :category
  has_and_belongs_to_many :authors
  
  define_index do
    indexes subject
    indexes content
    indexes tags.text, :as => :tags
    indexes comments.content, :as => :comments
    indexes authors.name, :as => :authors
    indexes keywords_file, :as => :keywords, :file => true
    
    has comments(:id), :as => :comment_ids, :source => :ranged_query,
      :facet => true
    has category.name, :facet => true, :as => :category_name, :type => :string
    has 'COUNT(DISTINCT comments.id)', :as => :comments_count, :type => :integer
    has comments.created_at, :as => :comments_created_at
  end
end
