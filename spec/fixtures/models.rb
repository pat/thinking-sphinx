class Tag < ActiveRecord::Base
  belongs_to :person
  belongs_to :football_team
  belongs_to :cricket_team
end

class FootballTeam < ActiveRecord::Base
  has_many :tags
  has_many :people, :through => :tags
end

class CricketTeam < ActiveRecord::Base
  has_many :people, :foreign_key => :team_id

  define_index do
    indexes :name
    has "SELECT cricket_team_id, id FROM tags", :source => :query, :as => :tags
  end
end

class Contact < ActiveRecord::Base
  belongs_to :person
end

class Friendship < ActiveRecord::Base
  belongs_to :person
  belongs_to :friend, :class_name => "Person", :foreign_key => :friend_id

  define_index do
    indexes "'something'", :as => :something
    has person_id, friend_id

    set_property :latitude_attr   => :person_id
    set_property :longitude_attr  => :person_id
  end

  sphinx_scope(:reverse) {
    {:order => "@weight ASC"}
  }
end

class Link < ActiveRecord::Base
  has_and_belongs_to_many :people
end

class Person < ActiveRecord::Base
  belongs_to :team, :polymorphic => :true
  belongs_to :source, :polymorphic => :true
  has_many :contacts

  has_many :friendships
  has_many :friends, :through => :friendships

  has_many :tags
  has_many :football_teams, :through => :tags

  has_and_belongs_to_many :links

  define_index do
    indexes [first_name, middle_initial, last_name], :as => :name
    indexes team.name, :as => :team_name
    indexes contacts.phone_number, :as => :phone_numbers
    indexes city,   :prefixes => true, :facet => true
    indexes state,  :infixes  => true, :facet => true

    has [first_name, middle_initial, last_name], :as => :name_sort
    has team.name, :as => :team_name_sort

    has [:id, :team_id], :as => :ids
    has team(:id), :as => :team_id
    has football_teams(:id), :as => :football_team_id

    has contacts.phone_number, :as => :phone_number_sort
    has contacts(:id), :as => :contact_ids

    has birthday, :facet => true

    has friendships.person_id, :as => :friendly_ids

    has :id, :as => :latitude
    has :id, :as => :longitude

    set_property :delta => true
  end
end

class Parent < Person
end

module Admin
  class Person < ::Person
  end
end

class Child < Person
  belongs_to :parent
  define_index do
    indexes [parent.first_name, parent.middle_initial, parent.last_name], :as => :parent_name
  end
end

class Teenager < Child
end

class Alpha < ActiveRecord::Base
  has_many :betas, :class_name => 'Beta'
  has_many :thetas

  define_index do
    indexes :name, :sortable => true

    has :id, :as => :lat
    has :id, :as => :lng

    set_property :field_weights => {"name" => 10}
  end

  def big_name
    name.upcase
  end

  def sphinx_attributes
    :existing
  end
end

class Beta < ActiveRecord::Base
  has_many :gammas

  define_index do
    indexes :name, :sortable => true

    has :id, :as => :lat
    has :id, :as => :lon

    set_property :delta => true
  end

  def excerpts
    false
  end

  def matching_fields
    :foo
  end
end

class Gamma < ActiveRecord::Base
  #
end

class Theta < ActiveRecord::Base
  #
end

class Search < ActiveRecord::Base
  #
end

class BigFoo < ActiveRecord::Base
  define_index do
    indexes name
  end
end
