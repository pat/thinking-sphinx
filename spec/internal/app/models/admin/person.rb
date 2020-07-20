# frozen_string_literal: true

class Admin::Person < ActiveRecord::Base
  self.table_name = 'admin_people'

  ThinkingSphinx::Callbacks.append(
    self, 'admin/person', :behaviours => [:sql, :real_time]
  )
end
