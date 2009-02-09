module AfterCommit
  module ActiveRecord
    # Based on the code found in Thinking Sphinx:
    # http://ts.freelancing-gods.com/ which was based on code written by Eli
    # Miller:
    # http://elimiller.blogspot.com/2007/06/proper-cache-expiry-with-aftercommit.html
    # with slight modification from Joost Hietbrink. And now me! Whew.
    def self.included(base)
      base.class_eval do
        # The define_callbacks method was added post Rails 2.0.2 - if it
        # doesn't exist, we define the callback manually
        if respond_to?(:define_callbacks)
          define_callbacks  :after_commit,
                            :after_commit_on_create,
                            :after_commit_on_update,
                            :after_commit_on_destroy
        else
          class << self
            # Handle after_commit callbacks - call all the registered callbacks.
            def after_commit(*callbacks, &block)
              callbacks << block if block_given?
              write_inheritable_array(:after_commit, callbacks)
            end
            
            def after_commit_on_create(*callbacks, &block)
              callbacks << block if block_given?
              write_inheritable_array(:after_commit_on_create, callbacks)
            end
            
            def after_commit_on_update(*callbacks, &block)
              callbacks << block if block_given?
              write_inheritable_array(:after_commit_on_update, callbacks)
            end
            
            def after_commit_on_destroy(*callbacks, &block)
              callbacks << block if block_given?
              write_inheritable_array(:after_commit_on_destroy, callbacks)
            end
          end
        end

        after_save    :add_committed_record
        after_create  :add_committed_record_on_create
        after_update  :add_committed_record_on_update
        after_destroy :add_committed_record_on_destroy

        # We need to keep track of records that have been saved or destroyed
        # within this transaction.
        def add_committed_record
          AfterCommit.committed_records << self
        end
        
        def add_committed_record_on_create
          AfterCommit.committed_records_on_create << self
        end
        
        def add_committed_record_on_update
          AfterCommit.committed_records_on_update << self
        end
        
        def add_committed_record_on_destroy
          AfterCommit.committed_records << self
          AfterCommit.committed_records_on_destroy << self
        end
        
        def after_commit
          # Deliberately blank.
        end

        # Wraps a call to the private callback method so that the the
        # after_commit callback can be made from the ConnectionAdapters when
        # the commit for the transaction has finally succeeded. 
        def after_commit_callback
          @calling_after_commit ||= false
          return if @calling_after_commit
          
          @calling_after_commit = true
          callback(:after_commit)
          @calling_after_commit = false
        end
        
        def after_commit_on_create_callback
          callback(:after_commit_on_create)
        end
        
        def after_commit_on_update_callback
          callback(:after_commit_on_update)
        end
        
        def after_commit_on_destroy_callback
          callback(:after_commit_on_destroy)
        end
      end
    end
  end
end
