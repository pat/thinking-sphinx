# frozen_string_literal: true

ThinkingSphinx::Index.define 'admin/person', :with => :active_record do
  indexes name
end

ThinkingSphinx::Index.define 'admin/person', :with => :real_time, :name => 'admin_person_rt' do
  indexes name
end
