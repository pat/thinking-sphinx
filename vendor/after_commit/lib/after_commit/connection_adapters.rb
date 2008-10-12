module AfterCommit
  module ConnectionAdapters
    def self.included(base)
      base.class_eval do
        # The commit_db_transaction method gets called when the outermost
        # transaction finishes and everything inside commits. We want to
        # override it so that after this happens, any records that were saved
        # or destroyed within this transaction now get their after_commit
        # callback fired.
        def commit_db_transaction_with_callback          
          commit_db_transaction_without_callback
          trigger_after_commit_callbacks
          trigger_after_commit_on_create_callbacks
          trigger_after_commit_on_update_callbacks
          trigger_after_commit_on_destroy_callbacks
        end 
        alias_method_chain :commit_db_transaction, :callback

        # In the event the transaction fails and rolls back, nothing inside
        # should recieve the after_commit callback.
        def rollback_db_transaction_with_callback
          rollback_db_transaction_without_callback

          AfterCommit.committed_records = []
          AfterCommit.committed_records_on_create = []
          AfterCommit.committed_records_on_update = []
          AfterCommit.committed_records_on_destroy = []
        end
        alias_method_chain :rollback_db_transaction, :callback
        
        protected        
          def trigger_after_commit_callbacks
            # Trigger the after_commit callback for each of the committed
            # records.
            if AfterCommit.committed_records.any?
              AfterCommit.committed_records.each do |record|
                begin
                  record.after_commit_callback
                rescue
                end
              end 
            end 

            # Make sure we clear out our list of committed records now that we've
            # triggered the callbacks for each one. 
            AfterCommit.committed_records = []
          end
        
          def trigger_after_commit_on_create_callbacks
            # Trigger the after_commit_on_create callback for each of the committed
            # records.
            if AfterCommit.committed_records_on_create.any?
              AfterCommit.committed_records_on_create.each do |record|
                begin
                  record.after_commit_on_create_callback
                rescue
                end
              end 
            end 

            # Make sure we clear out our list of committed records now that we've
            # triggered the callbacks for each one. 
            AfterCommit.committed_records_on_create = []
          end
        
          def trigger_after_commit_on_update_callbacks
            # Trigger the after_commit_on_update callback for each of the committed
            # records.
            if AfterCommit.committed_records_on_update.any?
              AfterCommit.committed_records_on_update.each do |record|
                begin
                  record.after_commit_on_update_callback
                rescue
                end
              end 
            end 

            # Make sure we clear out our list of committed records now that we've
            # triggered the callbacks for each one. 
            AfterCommit.committed_records_on_update = []
          end
        
          def trigger_after_commit_on_destroy_callbacks
            # Trigger the after_commit_on_destroy callback for each of the committed
            # records.
            if AfterCommit.committed_records_on_destroy.any?
              AfterCommit.committed_records_on_destroy.each do |record|
                begin
                  record.after_commit_on_destroy_callback
                rescue
                end
              end 
            end 

            # Make sure we clear out our list of committed records now that we've
            # triggered the callbacks for each one. 
            AfterCommit.committed_records_on_destroy = []
          end
        #end protected
      end 
    end 
  end
end
