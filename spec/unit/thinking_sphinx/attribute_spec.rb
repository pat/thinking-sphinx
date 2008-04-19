require 'spec/spec_helper'

describe ThinkingSphinx::Attribute do
  describe "to_select_sql method" do
    before :each do
      class Person < ActiveRecord::Base
        belongs_to :team, :polymorphic => :true
        has_many :contacts
        
        define_index do
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
      
      @index = Person.indexes.first
      @index.link!
    end
    
    it "should concat with spaces if there's more than one non-integer column" do
      @index.attributes[0].to_select_sql.should match(/CONCAT_WS\(' ', /)
    end
    
    it "should concat with spaces if there's more than one association for a non-integer column" do
      @index.attributes[1].to_select_sql.should match(/CONCAT_WS\(' ', /)
    end
    
    it "should concat with commas if there's multiple integer columns" do
      @index.attributes[2].to_select_sql.should match(/CONCAT_WS\(',', /)
    end
    
    it "should concat with commas if there's more than one association for an integer column" do
      @index.attributes[3].to_select_sql.should match(/CONCAT_WS\(',', /)
    end
    
    it "should group with spaces if there's string columns from a has_many or has_and_belongs_to_many association" do
      @index.attributes[4].to_select_sql.should match(/GROUP_CONCAT\(.+ SEPARATOR ' '\)/)
    end
    
    it "should group with commas if there's integer columns from a has_many or has_and_belongs_to_many association" do
      @index.attributes[5].to_select_sql.should match(/GROUP_CONCAT\(.+ SEPARATOR ','\)/)
    end
    
    it "should convert datetime values to timestamps" do
      @index.attributes[6].to_select_sql.should match(/UNIX_TIMESTAMP/)
    end
  end
  
  describe "to_group_sql method" do
    before :each do
      @attribute = ThinkingSphinx::Attribute.new([])
      @attribute.stub_method(:is_many? => false, :is_string? => false)
      
      ThinkingSphinx.stub_method(:use_group_by_shortcut? => false)
    end
    
    it "should return nil if is_many?" do
      @attribute.stub_method(:is_many? => true)
      
      @attribute.to_group_sql.should be_nil
    end
    
    it "should return nil if is_string?" do
      @attribute.stub_method(:is_string? => true)
      
      @attribute.to_group_sql.should be_nil
    end
    
    it "should return nil if group_by shortcut is allowed" do
      ThinkingSphinx.stub_method(:use_group_by_shortcut? => true)
      
      @attribute.to_group_sql.should be_nil
    end
    
    it "should return an array if neither is_many? or shortcut allowed" do
      @attribute.to_group_sql.should be_a_kind_of(Array)
    end
  end
end