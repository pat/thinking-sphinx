class ThinkingSphinx::DataMapper::Association
  attr_accessor :parent, :reflection, :join
  
  # Create a new association by passing in the parent association, and the
  # corresponding reflection instance. If there is no parent, pass in nil.
  # 
  #   top   = Association.new nil, top_reflection
  #   child = Association.new top, child_reflection
  # 
  def initialize(parent, reflection)
    @parent, @reflection = parent, reflection
    @children = {}
  end
  
  # Get the children associations for a given association name. The only time
  # that there'll actually be more than one association is when the
  # relationship is polymorphic. To keep things simple though, it will always
  # be an Array that gets returned (an empty one if no matches).
  #
  #   # where pages is an association on the class tied to the reflection.
  #   association.children(:pages)
  # 
  def children(assoc)
    @children[assoc] ||= ThinkingSphinx::DataMapper::Association.children(@reflection.child_model, assoc, self)
  end
  
  # Get the children associations for a given class, association name and
  # parent association. Much like the instance method of the same name, it
  # will return an empty array if no associations have the name, and only
  # have multiple association instances if the underlying relationship is
  # polymorphic.
  # 
  #   Association.children(User, :pages, user_association)
  # 
  def self.children(klass, assoc, parent=nil)
    ref = klass.relationships[assoc.to_s]
    
    ref.nil? ? [] : [ThinkingSphinx::DataMapper::Association.new(parent, ref)]
  end
  
  # Returns the association's join SQL statements - and it replaces
  # ::ts_join_alias:: with the aliased table name so the generated reflection
  # join conditions avoid column name collisions.
  # 
  def to_sql
    @join.association_join.gsub(/::ts_join_alias::/,
      "#{@reflection.klass.connection.quote_table_name(@join.parent.aliased_table_name)}"
    )
  end
  
  # Returns true if the association - or a parent - is a has_many or
  # has_and_belongs_to_many.
  # 
  def is_many?
    case @reflection
    when DataMapper::Associations::OneToMany,
         DataMapper::Associations::ManyToMany
      true
    else
      @parent ? @parent.is_many? : false
    end
  end
  
  # Returns an array of all the associations that lead to this one - starting
  # with the top level all the way to the current association object.
  # 
  def ancestors
    (parent ? parent.ancestors : []) << self
  end
  
  def has_column?(column)
    @reflection.child_model.properties.any? { |property|
      property.name == column.to_s
    }
  end
  
  def primary_key_from_reflection
    if @reflection.options[:through]
      @reflection.source_reflection.options[:foreign_key] ||
      @reflection.source_reflection.primary_key_name
    elsif @reflection.is_a?(DataMapper::Associations::ManyToMany)
      @reflection.association_foreign_key
    else
      nil
    end
  end
  
  def table
    if @reflection.options[:through] ||
      @reflection.is_a?(DataMapper::Associations::ManyToMany)
      @join.aliased_join_table_name
    else
      @join.aliased_table_name
    end
  end
end
