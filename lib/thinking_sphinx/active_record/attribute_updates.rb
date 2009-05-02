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
        return unless ThinkingSphinx.updates_enabled? && ThinkingSphinx.sphinx_running?
        
        config = ThinkingSphinx::Configuration.instance
        client = Riddle::Client.new config.address, config.port
        
        self.sphinx_indexes.each do |index|
          attribute_pairs  = attribute_values_for_index(index)
          attribute_names  = attribute_pairs.keys
          attribute_values = attribute_names.collect { |key|
            attribute_pairs[key]
          }
          
          client.update "#{index.name}_core", attribute_names, {
            sphinx_document_id => attribute_values
          } if in_core_index?
        end
      end
      
      def updatable_attributes(index)
        index.attributes.select { |attrib| attrib.updatable? }
      end
      
      def attribute_values_for_index(index)
        updatable_attributes(index).inject({}) { |hash, attrib|
          if attrib.type == :datetime
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