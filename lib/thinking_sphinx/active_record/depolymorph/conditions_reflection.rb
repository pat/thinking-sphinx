# frozen_string_literal: true

# The conditions approach is only available in Rails 3. This behaviour is
# superseded by ScopedReflection for Rails 4.0.
class ThinkingSphinx::ActiveRecord::Depolymorph::ConditionsReflection <
  ThinkingSphinx::ActiveRecord::Depolymorph::BaseReflection

  def call
    klass.new reflection.macro, name, options, active_record
  end

  private

  delegate :foreign_type, :active_record, :to => :reflection

  def condition
    "::ts_join_alias::.#{quoted_foreign_type} = '#{class_name}'"
  end

  def options
    super

    case @options[:conditions]
    when nil
      @options[:conditions] = condition
    when Array
      @options[:conditions] << condition
    when Hash
      @options[:conditions].merge! foreign_type => @options[:class_name]
    else
      @options[:conditions] << " AND #{condition}"
    end

    @options
  end

  def quoted_foreign_type
    active_record.connection.quote_column_name foreign_type
  end
end
