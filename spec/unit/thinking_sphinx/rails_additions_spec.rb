require 'spec/spec_helper'

describe ThinkingSphinx::HashExcept do
  before(:each) do
    @hash = { :number => 20, :letter => 'b', :shape => 'rectangle' }
  end
  
  describe "except method" do
    it "returns a hash without the specified keys" do
      new_hash = @hash.except(:number)
      new_hash.should_not have_key(:number)
    end
  end
  
  describe "except! method" do
    it "modifies hash removing specified keys" do
      @hash.except!(:number)
      @hash.should_not have_key(:number)
    end
  end
  
  describe "extends Hash" do
    it 'with except' do
      Hash.instance_methods.include?('except').should be_true
    end

    it 'with except!' do
      Hash.instance_methods.include?('except!').should be_true
    end
  end
end

describe ThinkingSphinx::ArrayExtractOptions do
  describe 'extract_options! method' do
    it 'returns a hash' do
      array = []
      array.extract_options!.should be_kind_of(Hash)
    end

    it 'returns the last option if it is a hash' do
      array = ['a', 'b', {:c => 'd'}]
      array.extract_options!.should == {:c => 'd'}
    end
  end
  
  describe "extends Array" do
    it 'with extract_options!' do
      Array.instance_methods.include?('extract_options!').should be_true
    end
  end
end

describe ThinkingSphinx::AbstractQuotedTableName do
  describe 'quote_table_name method' do
    it 'calls quote_column_name' do
      adapter = ActiveRecord::ConnectionAdapters::AbstractAdapter.new('mysql')
      adapter.should_receive(:quote_column_name).with('messages')
      adapter.quote_table_name('messages')
    end
  end
  
  describe "extends ActiveRecord::ConnectionAdapters::AbstractAdapter" do
    it 'with quote_table_name' do
      ActiveRecord::ConnectionAdapters::AbstractAdapter.instance_methods.include?('quote_table_name').should be_true
    end
  end
end

describe ThinkingSphinx::MysqlQuotedTableName do
  describe "quote_table_name method" do
    it 'calls quote_column_name' do
      pending "Needs NotAMock"
      adapter = ActiveRecord::ConnectionAdapters::MysqlAdapter.new
      adapter.should_receive(:quote_column_name).with('messages')
      adapter.quote_table_name('messages')
    end
  end
  
  describe "extends ActiveRecord::ConnectionAdapters::MysqlAdapter" do
    it 'with quote_table_name' do
      ActiveRecord::ConnectionAdapters::MysqlAdapter.instance_methods.include?("quote_table_name").should be_true
    end
  end  
end

describe ThinkingSphinx::ActiveRecordQuotedName do
  describe "quoted_table_name method" do
    it 'returns table name wrappd in quotes' do
      Person.quoted_table_name.should == '`people`'
    end
  end
  
  describe "extends ActiveRecord::Base" do
    it 'with quoted_table_name' do
      ActiveRecord::Base.respond_to?("quoted_table_name").should be_true
    end
  end
end

describe ThinkingSphinx::ActiveRecordStoreFullSTIClass do
  describe "store_full_sti_class method" do
    it 'returns false' do
      Person.store_full_sti_class.should be_false
    end
  end
  
  describe "extends ActiveRecord::Base" do
    it 'with store_full_sti_class' do
      ActiveRecord::Base.respond_to?(:store_full_sti_class).should be_true
    end
  end
end

class TestModel
  @@squares = 89
  @@circles = 43
  
  def number_of_polygons
    @@polygons
  end
end

describe ThinkingSphinx::ClassAttributeMethods do
  describe "cattr_reader method" do
    it 'creates getters' do
      TestModel.cattr_reader :herbivores
      test_model = TestModel.new
      test_model.respond_to?(:herbivores).should be_true
    end

    it 'sets the initial value to nil' do
      TestModel.cattr_reader :carnivores
      test_model = TestModel.new
      test_model.carnivores.should be_nil
    end

    it 'does not override an existing definition' do
      TestModel.cattr_reader :squares
      test_model = TestModel.new
      test_model.squares.should == 89      
    end
  end

  describe "cattr_writer method" do
    it 'creates setters' do
      TestModel.cattr_writer :herbivores
      test_model = TestModel.new
      test_model.respond_to?(:herbivores=).should be_true
    end
    
    it 'does not override an existing definition' do
      TestModel.cattr_writer :polygons
      test_model = TestModel.new
      test_model.polygons = 100
      test_model.number_of_polygons.should == 100
    end
  end

  describe "cattr_accessor method" do
    it 'calls cattr_reader' do
      Class.should_receive(:cattr_reader).with('polygons')
      Class.cattr_accessor('polygons')
    end

    it 'calls cattr_writer' do
      Class.should_receive(:cattr_writer).with('polygons')
      Class.cattr_accessor('polygons')
    end
  end

  describe "extends Class" do
    it 'with cattr_reader' do
      Class.respond_to?('cattr_reader').should be_true
    end

    it 'with cattr_writer' do
      Class.respond_to?('cattr_writer').should be_true
    end

    it 'with cattr_accessor' do
      Class.respond_to?('cattr_accessor').should be_true
    end
  end
end
