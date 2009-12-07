module ThinkingSphinx
  module ActiveRecord
    module AttributeUpdates
      def self.included(base)
        base.class_eval do
          after_commit :update_attribute_values
        end
      end
      
      private
            
      def update_attribute_values
        return true unless ThinkingSphinx.updates_enabled? &&
          ThinkingSphinx.sphinx_running?
        
        config = ThinkingSphinx::Configuration.instance
        client = config.client
        
        self.class.sphinx_indexes.each do |index|
          attribute_pairs  = attribute_values_for_index(index)
          attribute_names  = attribute_pairs.keys
          attribute_values = attribute_names.collect { |key|
            attribute_pairs[key]
          }
          
          client.update "#{index.core_name}", attribute_names, {
            sphinx_document_id => attribute_values
          } if self.class.search_for_id(sphinx_document_id, index.core_name)
        end
        
        true
      end
      
      def updatable_attributes(index)
        index.attributes.select { |attrib| attrib.updatable? }
      end
      
      def attribute_values_for_index(index)
        updatable_attributes(index).inject({}) { |hash, attrib|
          if attrib.type == :datetime && attrib.live_value(self)
            hash[attrib.unique_name.to_s] = attrib.live_value(self).to_time.to_i
          else
            hash[attrib.unique_name.to_s] = attrib.live_value self
          end
          
          hash
        }
      end
    end
  end
end
