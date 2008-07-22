Gem::Specification.new do |s|
  s.name              = "thinking-sphinx"
  s.version           = "0.9.8"
  s.summary           = "A concise and easy-to-use Ruby library that connects ActiveRecord to the Sphinx search daemon, managing configuration, indexing and searching."
  s.description       = "A concise and easy-to-use Ruby library that connects ActiveRecord to the Sphinx search daemon, managing configuration, indexing and searching."
  s.author            = "Pat Allan"
  s.email             = "pat@freelancing-gods.com"
  s.homepage          = "http://ts.freelancing-gods.com"
  s.has_rdoc          = true
  s.rdoc_options     << "--title" << "Thinking Sphinx -- Rails/Merb Sphinx Plugin" <<
                        "--line-numbers"
  s.rubyforge_project = "thinking-sphinx"
  s.test_files        = ["spec/unit/thinking_sphinx/active_record/delta_spec.rb", "spec/unit/thinking_sphinx/active_record/has_many_association_spec.rb", "spec/unit/thinking_sphinx/active_record/search_spec.rb", "spec/unit/thinking_sphinx/active_record_spec.rb", "spec/unit/thinking_sphinx/association_spec.rb", "spec/unit/thinking_sphinx/attribute_spec.rb", "spec/unit/thinking_sphinx/configuration_spec.rb", "spec/unit/thinking_sphinx/field_spec.rb", "spec/unit/thinking_sphinx/index/builder_spec.rb", "spec/unit/thinking_sphinx/index/faux_column_spec.rb", "spec/unit/thinking_sphinx/index_spec.rb", "spec/unit/thinking_sphinx/search_spec.rb", "spec/unit/thinking_sphinx_spec.rb"]
  s.files             = ["lib/riddle/client/filter.rb", "lib/riddle/client/message.rb", "lib/riddle/client/response.rb", "lib/riddle/client.rb", "lib/riddle.rb", "lib/test.rb", "lib/thinking_sphinx/active_record/delta.rb", "lib/thinking_sphinx/active_record/has_many_association.rb", "lib/thinking_sphinx/active_record/search.rb", "lib/thinking_sphinx/active_record.rb", "lib/thinking_sphinx/association.rb", "lib/thinking_sphinx/attribute.rb", "lib/thinking_sphinx/configuration.rb", "lib/thinking_sphinx/field.rb", "lib/thinking_sphinx/index/builder.rb", "lib/thinking_sphinx/index/faux_column.rb", "lib/thinking_sphinx/index.rb", "lib/thinking_sphinx/rails_additions.rb", "lib/thinking_sphinx/search.rb", "lib/thinking_sphinx.rb", "LICENCE", "README", "tasks/thinking_sphinx_tasks.rb", "tasks/thinking_sphinx_tasks.rake"]
end