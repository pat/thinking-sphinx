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
        #    default_sphinx_scope {
        #         { :order => 'created_at DESC' }
        #       }
        #
        # The scope is automatically applied when the search method is called.
        # The default_scope can also be created using:
        #
        #   sphinx_scope(:default) {
        #         { :order => 'created_at DESC' }
        #      }
        #
        def default_sphinx_scope(&block)
          sphinx_scope(:default, &block)
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
          
          metaclass.instance_eval do
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
            metaclass.send(:undef_method, scope)
          end
          
          sphinx_scopes.clear
        end
      end
    end
  end
end
