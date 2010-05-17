module ThinkingSphinx::ActiveRecord::Arel
  def to_sql(options = {})
    relation = @model.scoped
    pre_select = 'SQL_NO_CACHE ' if adapter.sphinx_identifier == "mysql"
    relation = relation.select(pre_select.to_s + sql_select_clause(options[:offset]))
    all_associations.each do |assoc|
      # I'd like to do this but doesn't work yet..
      # relation = relation.joins(assoc.reflection.name, ::Arel::OuterJoin)
      relation = relation.joins(assoc.join.with_join_class(::Arel::OuterJoin))
    end
    
    unless @index.options[:disable_range]
      relation = relation.where("#{@model.quoted_table_name}.#{quote_column(@model.primary_key_for_sphinx)} >= $start") 
      relation = relation.where("#{@model.quoted_table_name}.#{quote_column(@model.primary_key_for_sphinx)} <= $end")
    end
    
    if self.delta? && !@index.delta_object.clause(@model, options[:delta]).blank?
      relation = relation.where(@index.delta_object.clause(@model, options[:delta]))
    end
    
    relation = relation.group(sql_group_clause)
    relation = relation.order('NULL') if adapter.sphinx_identifier == "mysql"
    relation.to_sql
  end
end