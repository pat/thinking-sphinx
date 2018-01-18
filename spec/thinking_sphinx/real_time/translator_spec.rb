# frozen_string_literal: true

require 'spec_helper'

describe ThinkingSphinx::RealTime::Translator do
  let(:subject) { ThinkingSphinx::RealTime::Translator.call object, column }
  let(:object)  { double }
  let(:column)  { double :__stack => [], :__name => :title }

  it "converts non-UTF-8 strings to UTF-8" do
    allow(object).to receive(:title).
      and_return "hello".dup.force_encoding("ASCII-8BIT")

    expect(subject).to eq("hello")
    expect(subject.encoding.name).to eq("UTF-8")
  end
end
