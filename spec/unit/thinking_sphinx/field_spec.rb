require 'spec/spec_helper'

describe ThinkingSphinx::Field do
  describe "to_select_sql method" do
    before :each do
      class Person < ActiveRecord::Base
        define_index do
          indexes [first_name, middle_initial, last_name], :as => :name
        end
      end
      
      Person.indexes.first.link!
    end
    
    it "should concat with spaces if there are multiple columns" do
      Person.indexes.first.fields.first.to_select_sql.should match(/CONCAT_WS\(' ', /)
    end
    
    it "should concat with spaces if a column has more than one association"
    
    it "should group if any association for any column is a has_many or has_and_belongs_to_many"
  end
end