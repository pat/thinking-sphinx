module ThinkingSphinx
  module ActiveRecord
    # This module contains all the delta-related code for models. There isn't
    # really anything you need to call manually in here - except perhaps
    # index_delta, but not sure what reason why.
    # 
    module Delta
      # Code for after_commit callback is written by Eli Miller:
      # http://elimiller.blogspot.com/2007/06/proper-cache-expiry-with-aftercommit.html
      # with slight modification from Joost Hietbrink.
      #
      def self.included(base)
        base.class_eval do
          class << self
            # Build the delta index for the related model. This won't be called
            # if running in the test environment.
            #
            def index_delta(instance = nil)
              delta_object.index(self, instance)
            end
            
            def delta_object
              self.sphinx_indexes.first.delta_object
            end
          end
          
          def toggled_delta?
            self.class.delta_object.toggled(self)
          end
          
          private
          
          # Set the delta value for the model to be true.
          def toggle_delta
            self.class.delta_object.toggle(self) if should_toggle_delta?
          end
          
          # Build the delta index for the related model. This won't be called
          # if running in the test environment.
          # 
          def index_delta
            self.class.index_delta(self) if self.class.delta_object.toggled(self)
          end
          
          def should_toggle_delta?
            self.new_record? || indexed_data_changed?
          end
          
          def indexed_data_changed?
            sphinx_indexes.any? { |index|
              index.fields.any? { |field| field.changed?(self) } ||
              index.attributes.any? { |attrib|
                attrib.public? && attrib.changed?(self) && !attrib.updatable?
              }
            }
          end
        end
      end
    end
  end
end
