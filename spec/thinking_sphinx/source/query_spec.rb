require 'spec/spec_helper'

describe ThinkingSphinx::Source::Query do
  before :each do
    @adapter = ThinkingSphinx::MysqlAdapter.new(Alpha)
    @query   = ThinkingSphinx::Source::Query.new('alphas', @adapter)
  end
  
  describe '#initialize' do
    it "should select everything from the model's table by default" do
      @query.to_s.should == "SELECT * FROM `alphas`"
    end
  end
  
  describe '#add_column' do
    it "should reference the default table if none supplied" do
      @query.add_column 'name'
      @query.to_s.should == "SELECT `alphas`.`name` FROM `alphas`"
    end
  end
  
  describe '#add_join' do
    it "should add a LEFT OUTER JOIN for the given details" do
      @query.add_join 'alphas', 'id', 'betas', 'alpha_id'
      @query.to_s.should == "SELECT * FROM `alphas` LEFT OUTER JOIN `betas` AS `betas` ON `alphas`.`id` = `betas`.`alpha_id`"
    end
  end
end
