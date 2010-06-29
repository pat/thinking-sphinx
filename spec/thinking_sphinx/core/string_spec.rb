require 'spec_helper'

describe String do  
  describe "to_crc32 instance method" do
    it "should return an integer" do
      'to_crc32'.to_crc32.should be_a_kind_of(Integer)
    end
  end
end    