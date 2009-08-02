module ThinkingSphinx
  module ActiveRecord
    module Scopes
      def self.included(base)
        base.class_eval do
          extend ThinkingSphinx::ActiveRecord::Scopes::ClassMethods
        end
      end
    
      module ClassMethods
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
