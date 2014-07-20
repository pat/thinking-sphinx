# encoding: utf-8
module ThinkingSphinx; end

require './lib/thinking_sphinx/wildcard'

describe ThinkingSphinx::Wildcard do
  describe '.call' do
    it "does not star quorum operators" do
      ThinkingSphinx::Wildcard.call("foo/3").should == "*foo*/3"
    end

    it "does not star proximity operators or quoted strings" do
      ThinkingSphinx::Wildcard.call(%q{"hello world"~3}).
        should == %q{"hello world"~3}
    end

    it "treats slashes as a separator when starring" do
      ThinkingSphinx::Wildcard.call("a\\/c").should == "*a*\\/*c*"
    end

    it "separates escaping from the end of words" do
      ThinkingSphinx::Wildcard.call("\\(913\\)").should == "\\(*913*\\)"
    end

    it "ignores escaped slashes" do
      ThinkingSphinx::Wildcard.call("\\/\\/pan").should == "\\/\\/*pan*"
    end

    it "does not star manually provided field tags" do
      ThinkingSphinx::Wildcard.call("@title pan").should == "@title *pan*"
    end

    it "does not star manually provided arrays of field tags" do
      ThinkingSphinx::Wildcard.call("@(title, body) pan").
        should == "@(title, body) *pan*"
    end

    it "handles nil queries" do
      ThinkingSphinx::Wildcard.call(nil).should == ''
    end

    it "handles unicode values" do
      ThinkingSphinx::Wildcard.call('älytön').should == '*älytön*'
    end
  end
end
