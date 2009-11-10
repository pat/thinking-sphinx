# Fix problems caused because tests all run in a single transaction.

# The single transaction means that after_commit callback never happens in tests.  Each of these method definitions
# overwrites the method in the after_commit plugin that stores the callback for after the commit.  In each case here
# we simply call the callback rather than waiting for a commit that will never come.

module AfterCommit::TestBypass
  def self.included(klass)
    klass.class_eval do
      [:add_committed_record, :add_committed_record_on_create, :add_committed_record_on_update, :add_committed_record_on_destroy].each do |method|
        remove_method(method)
      end
    end
  end

  def add_committed_record
    after_commit_callback
  end

  def add_committed_record_on_create
    after_commit_on_create_callback
  end

  def add_committed_record_on_update
    after_commit_on_update_callback
  end

  def add_committed_record_on_destroy
    after_commit_on_destroy_callback
  end
end
