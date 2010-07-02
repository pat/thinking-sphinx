require 'spec_helper'
require "#{File.dirname(__FILE__)}/../../lib/thinking_sphinx/test"

describe ThinkingSphinx::Test do
  describe ".run" do
    before :each do
      ThinkingSphinx::Test.stub!(:start)
    end

    it "should call stop when an exception is raised by passed block" do
      ThinkingSphinx::Test.should_receive(:stop)
      
      begin
        ThinkingSphinx::Test.run { raise FakeError }
      rescue => FakeError
        # we raised it manually ourselves!
      end
    end
  end
end
