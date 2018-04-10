# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ThinkingSphinx::RealTime::TranscribeInstance do
  let(:subject) do
    ThinkingSphinx::RealTime::TranscribeInstance.call(
      instance, index, [property_a, property_b, property_c]
    )
  end
  let(:instance)   { double :id => 43 }
  let(:index)      { double :document_id_for_key => 46 }
  let(:property_a) { double :translate => 'A' }
  let(:property_b) { double :translate => 'B' }
  let(:property_c) { double :translate => 'C' }

  it 'returns an array of each translated property, and the document id' do
    expect(subject).to eq([46, 'A', 'B', 'C'])
  end

  it 'raises an error if something goes wrong' do
    allow(property_b).to receive(:translate).and_raise(StandardError)

    expect { subject }.to raise_error(ThinkingSphinx::TranscriptionError)
  end

  it 'notes the instance and property in the wrapper error' do
    allow(property_b).to receive(:translate).and_raise(StandardError)

    expect { subject }.to raise_error do |wrapper|
      expect(wrapper.instance).to eq(instance)
      expect(wrapper.property).to eq(property_b)
    end
  end
end
