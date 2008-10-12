ActiveRecord::Base.send(:include, AfterCommit::ActiveRecord)

Object.subclasses_of(ActiveRecord::ConnectionAdapters::AbstractAdapter).each do |klass|
  klass.send(:include, AfterCommit::ConnectionAdapters)
end
