module ThinkingSphinx
  module ActiveRecord
    module Scopes
      def self.included(base)
        base.class_eval do
          extend ThinkingSphinx::ActiveRecord::Scopes::ClassMethods
        end
      end
    
      module ClassMethods
        
        # Similar to ActiveRecord's default_scope method Thinking Sphinx supports
        # a default_sphinx_scope. For example:
        #
        #    default_sphinx_scope :some_sphinx_named_scope
        #
        # The scope is automatically applied when the search method is called. It
        # will only be applied if it is an existing sphinx_scope.
        def default_sphinx_scope(sphinx_scope_name)
          @default_sphinx_scope = sphinx_scope_name
        end

        # Returns the default_sphinx_scope or nil if none is set.
        def get_default_sphinx_scope
          @default_sphinx_scope
        end

        # Returns true if the current Model has a default_sphinx_scope. Also checks if
        # the default_sphinx_scope actually is a scope.
        def has_default_sphinx_scope?
          !@default_sphinx_scope.nil? && sphinx_scopes.include?(@default_sphinx_scope)
        end

        # Similar to ActiveRecord's named_scope method Thinking Sphinx supports
        # scopes. For example:
        #
        #   sphinx_scope(:latest_first) { 
        #       {:order => 'created_at DESC, @relevance DESC'}
        #     }
        #
        # Usage:
        #
        #   @articles =  Article.latest_first.search 'pancakes'
        #
        def sphinx_scope(method, &block)
          @sphinx_scopes ||= []
          @sphinx_scopes << method
          
          singleton_class.instance_eval do
            define_method(method) do |*args|
              options = {:classes => classes_option}
              options.merge! block.call(*args)
              
              ThinkingSphinx::Search.new(options)
            end
          end
        end

        # This returns an Array of all defined scopes. The default
        # scope shows as :default.
        def sphinx_scopes
          @sphinx_scopes || []
        end
        
        def remove_sphinx_scopes
          sphinx_scopes.each do |scope|
            singleton_class.send(:undef_method, scope)
          end
          
          sphinx_scopes.clear
        end
      end
    end
  end
end
