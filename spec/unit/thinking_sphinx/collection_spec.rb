require 'spec/spec_helper'

describe ThinkingSphinx::Collection do
  it "should behave like WillPaginate::Collection" do
    instance_methods = ThinkingSphinx::Collection.instance_methods.collect { |m| m.to_s }
    instance_methods.should include("previous_page")
    instance_methods.should include("next_page")
    instance_methods.should include("current_page")
    instance_methods.should include("total_pages")
    instance_methods.should include("total_entries")
    instance_methods.should include("offset")
    
    ThinkingSphinx::Collection.ancestors.should include(Array)
  end
end