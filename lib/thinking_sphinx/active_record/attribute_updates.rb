module ThinkingSphinx
  module ActiveRecord
    module AttributeUpdates
      def self.included(base)
        base.class_eval do
          after_save :update_attribute_values
        end
      end

      private

      def update_attribute_values
        return true unless ThinkingSphinx.updates_enabled? &&
          ThinkingSphinx.sphinx_running?

        self.class.sphinx_indexes.each do |index|
          attribute_pairs  = attribute_values_for_index(index)
          attribute_names  = attribute_pairs.keys
          attribute_values = attribute_names.collect { |key|
            attribute_pairs[key]
          }

          update_index index.core_name, attribute_names, attribute_values
          next unless index.delta?
          index.enumerate_delta_names do |delta_name|
            update_index delta_name, attribute_names, attribute_values
          end
        end

        true
      end

      def updatable_attributes(index)
        index.attributes.select { |attrib| attrib.updatable? }
      end

      def attribute_values_for_index(index)
        updatable_attributes(index).inject({}) { |hash, attrib|
          hash[attrib.unique_name.to_s] = attrib.live_value self
          hash
        }
      end

      def update_index(index_name, attribute_names, attribute_values)
        config = ThinkingSphinx::Configuration.instance
        config.client.update index_name, attribute_names, {
          sphinx_document_id => attribute_values
        }
      rescue Riddle::ConnectionError, Riddle::ResponseError,
        ThinkingSphinx::SphinxError, Errno::ETIMEDOUT
        # Not the end of the world if Sphinx isn't running.
      end
    end
  end
end
