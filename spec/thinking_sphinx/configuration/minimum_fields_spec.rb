# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ThinkingSphinx::Configuration::MinimumFields do
  let(:indices) { [index_a, index_b] }
  let(:index_a) { double 'Index A', :model => model_a, :type => 'plain',
    :sources => [double(:fields => [field_a1, field_a2])] }
  let(:index_b) { double 'Index B', :model => model_a, :type => 'rt',
    :fields => [field_b1, field_b2] }
  let(:field_a1) { double :name => 'sphinx_internal_class_name' }
  let(:field_a2) { double :name => 'name' }
  let(:field_b1) { double :name => 'sphinx_internal_class_name' }
  let(:field_b2) { double :name => 'name' }
  let(:model_a)  { double :inheritance_column => 'type',
    :table_exists? => true }
  let(:model_b)  { double :inheritance_column => 'type',
    :table_exists? => true }
  let(:subject)  { ThinkingSphinx::Configuration::MinimumFields.new indices }

  it 'removes the class name fields when no index models have type columns' do
    allow(model_a).to receive(:column_names).and_return(['id', 'name'])
    allow(model_b).to receive(:column_names).and_return(['id', 'name'])

    subject.reconcile

    expect(index_a.sources.first.fields).to eq([field_a2])
    expect(index_b.fields).to eq([field_b2])
  end

  it 'removes the class name fields when models have no tables' do
    allow(model_a).to receive(:table_exists?).and_return(false)
    allow(model_b).to receive(:table_exists?).and_return(false)

    subject.reconcile

    expect(index_a.sources.first.fields).to eq([field_a2])
    expect(index_b.fields).to eq([field_b2])
  end

  it 'keeps the class name fields when one index model has a type column' do
    allow(model_a).to receive(:column_names).and_return(['id', 'name', 'type'])
    allow(model_b).to receive(:column_names).and_return(['id', 'name'])

    subject.reconcile

    expect(index_a.sources.first.fields).to eq([field_a1, field_a2])
    expect(index_b.fields).to eq([field_b1, field_b2])
  end
end
