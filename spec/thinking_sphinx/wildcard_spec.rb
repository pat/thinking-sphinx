# encoding: utf-8
module ThinkingSphinx; end

require './lib/thinking_sphinx/wildcard'

describe ThinkingSphinx::Wildcard do
  describe '.call' do
    it "does not star quorum operators" do
      expect(ThinkingSphinx::Wildcard.call("foo/3")).to eq("*foo*/3")
    end

    it "does not star proximity operators or quoted strings" do
      expect(ThinkingSphinx::Wildcard.call(%q{"hello world"~3})).
        to eq(%q{"hello world"~3})
    end

    it "treats slashes as a separator when starring" do
      expect(ThinkingSphinx::Wildcard.call("a\\/c")).to eq("*a*\\/*c*")
    end

    it "separates escaping from the end of words" do
      expect(ThinkingSphinx::Wildcard.call("\\(913\\)")).to eq("\\(*913*\\)")
    end

    it "ignores escaped slashes" do
      expect(ThinkingSphinx::Wildcard.call("\\/\\/pan")).to eq("\\/\\/*pan*")
    end

    it "does not star manually provided field tags" do
      expect(ThinkingSphinx::Wildcard.call("@title pan")).to eq("@title *pan*")
    end

    it 'does not star multiple field tags' do
      expect(ThinkingSphinx::Wildcard.call("@title pan @tags food")).
        to eq("@title *pan* @tags *food*")
    end

    it "does not star manually provided arrays of field tags" do
      expect(ThinkingSphinx::Wildcard.call("@(title, body) pan")).
        to eq("@(title, body) *pan*")
    end

    it "handles nil queries" do
      expect(ThinkingSphinx::Wildcard.call(nil)).to eq('')
    end

    it "handles unicode values" do
      expect(ThinkingSphinx::Wildcard.call('älytön')).to eq('*älytön*')
    end
  end
end
