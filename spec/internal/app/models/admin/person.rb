class Admin::Person < ActiveRecord::Base
  self.table_name = 'admin_people'

  after_save ThinkingSphinx::RealTime.callback_for('admin/person')
end
