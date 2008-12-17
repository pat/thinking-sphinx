require 'spec/spec_helper'

describe ThinkingSphinx::Collection do
  it "should behave like WillPaginate::Collection" do
    ThinkingSphinx::Collection.instance_methods.should include("previous_page")
    ThinkingSphinx::Collection.instance_methods.should include("next_page")
    ThinkingSphinx::Collection.instance_methods.should include("current_page")
    ThinkingSphinx::Collection.instance_methods.should include("total_pages")
    ThinkingSphinx::Collection.instance_methods.should include("total_entries")
    ThinkingSphinx::Collection.instance_methods.should include("offset")
    
    ThinkingSphinx::Collection.ancestors.should include(Array)
  end
end