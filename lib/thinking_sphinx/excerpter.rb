module ThinkingSphinx
  class Excerpter
    CoreMethods = %w( kind_of? object_id respond_to? should should_not stub! )
    # Hide most methods, to allow them to be passed through to the instance.
    instance_methods.select { |method|
      method.to_s[/^__/].nil? && !CoreMethods.include?(method.to_s)
    }.each { |method|
      undef_method method
    }
    
    def initialize(search, instance)
      @search   = search
      @instance = instance
    end
    
    def method_missing(method, *args, &block)
      string = CGI::escapeHTML @instance.send(method, *args, &block).to_s
      
      @search.excerpt_for(string, @instance.class)
    end
  end
end
