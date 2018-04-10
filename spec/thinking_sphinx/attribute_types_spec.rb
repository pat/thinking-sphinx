# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ThinkingSphinx::AttributeTypes do
  let(:configuration) {
    double('configuration', :configuration_file => 'sphinx.conf')
  }

  before :each do
    allow(ThinkingSphinx::Configuration).to receive(:instance).
      and_return(configuration)

    allow(File).to receive(:exist?).with('sphinx.conf').and_return(true)
    allow(File).to receive(:read).with('sphinx.conf').and_return(<<-CONF)
index plain_index
{
  source = plain_source
}

source plain_source
{
  type = mysql
  sql_attr_uint = customer_id
  sql_attr_float = price
  sql_attr_multi = uint comment_ids from field
}

index rt_index
{
  type = rt
  rt_attr_uint = user_id
  rt_attr_multi = comment_ids
}
    CONF
  end

  it 'returns an empty hash if no configuration file exists' do
    allow(File).to receive(:exist?).with('sphinx.conf').and_return(false)

    expect(ThinkingSphinx::AttributeTypes.new.call).to eq({})
  end

  it 'returns all known attributes' do
    expect(ThinkingSphinx::AttributeTypes.new.call).to eq({
      'customer_id' => [:uint],
      'price'       => [:float],
      'comment_ids' => [:uint],
      'user_id'     => [:uint]
    })
  end
end
