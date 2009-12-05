module ThinkingSphinx
  module MetaClass
    def metaclass
      class << self
        self
      end
    end
  end
end

unless Object.new.respond_to?(:metaclass)
  Object.send(:include, ThinkingSphinx::MetaClass)
end
