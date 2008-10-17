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
            # Temporarily disable delta indexing inside a block, then perform a single
            # rebuild of index at the end.
            #
            # Useful when performing updates to batches of models to prevent
            # the delta index being rebuilt after each individual update.
            #
            # In the following example, the delta index will only be rebuilt once,
            # not 10 times.
            #
            #   SomeModel.suspended_delta do
            #     10.times do
            #       SomeModel.create( ... )
            #     end
            #   end
            #
            def suspended_delta(reindex_after = true, &block)
              original_setting = ThinkingSphinx.deltas_enabled?
              ThinkingSphinx.deltas_enabled = false
              begin
                yield
              ensure
                ThinkingSphinx.deltas_enabled = original_setting
                self.index_delta if reindex_after
              end
            end

            # Build the delta index for the related model. This won't be called
            # if running in the test environment.
            #
            def index_delta(instance = nil)
              return true unless ThinkingSphinx.updates_enabled? &&
                ThinkingSphinx.deltas_enabled?
              
              config = ThinkingSphinx::Configuration.instance
              client = Riddle::Client.new config.address, config.port
              
              client.update(
                "#{self.sphinx_indexes.first.name}_core",
                ['sphinx_deleted'],
                {instance.sphinx_document_id => 1}
              ) if instance && instance.in_core_index?
              
              system "#{config.bin_path}indexer --config #{config.config_file} --rotate #{self.sphinx_indexes.first.name}_delta"

              true
            end
          end
          
          private
          
          # Set the delta value for the model to be true.
          def toggle_delta
            self.delta = true
          end
          
          # Build the delta index for the related model. This won't be called
          # if running in the test environment.
          # 
          def index_delta
            self.class.index_delta(self)
          end
        end
      end
    end
  end
end
