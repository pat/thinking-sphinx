class Person < ActiveRecord::Base
  belongs_to :team, :polymorphic => :true
  has_many :contacts
  
  define_index do
    indexes [first_name, middle_initial, last_name], :as => :name
    indexes team.name, :as => :team_name
    indexes contacts.phone_number, :as => :phone_numbers
    
    has [first_name, middle_initial, last_name], :as => :name
    has team.name, :as => :team_name
    
    has [:id, :team_id], :as => :ids
    has team(:id), :as => :team_id
    
    has contacts.phone_number, :as => :phone_numbers
    has contacts(:id), :as => :contact_ids
    
    has birthday
  end
end

class Contact < ActiveRecord::Base
  belongs_to :person
end

class FootballTeam < ActiveRecord::Base
  #
end

class CricketTeam < ActiveRecord::Base
  #
end