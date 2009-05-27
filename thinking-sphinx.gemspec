# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{thinking-sphinx}
  s.version = "1.1.18"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Pat Allan"]
  s.date = %q{2009-05-27}
  s.description = %q{A concise and easy-to-use Ruby library that connects ActiveRecord to the Sphinx search daemon, managing configuration, indexing and searching.}
  s.email = %q{pat@freelancing-gods.com}
  s.files = ["lib/thinking_sphinx/active_record/attribute_updates.rb", "lib/thinking_sphinx/active_record/delta.rb", "lib/thinking_sphinx/active_record/has_many_association.rb", "lib/thinking_sphinx/active_record/search.rb", "lib/thinking_sphinx/active_record.rb", "lib/thinking_sphinx/adapters/abstract_adapter.rb", "lib/thinking_sphinx/adapters/mysql_adapter.rb", "lib/thinking_sphinx/adapters/postgresql_adapter.rb", "lib/thinking_sphinx/association.rb", "lib/thinking_sphinx/attribute.rb", "lib/thinking_sphinx/class_facet.rb", "lib/thinking_sphinx/collection.rb", "lib/thinking_sphinx/configuration.rb", "lib/thinking_sphinx/core/string.rb", "lib/thinking_sphinx/deltas/datetime_delta.rb", "lib/thinking_sphinx/deltas/default_delta.rb", "lib/thinking_sphinx/deltas/delayed_delta/delta_job.rb", "lib/thinking_sphinx/deltas/delayed_delta/flag_as_deleted_job.rb", "lib/thinking_sphinx/deltas/delayed_delta/job.rb", "lib/thinking_sphinx/deltas/delayed_delta.rb", "lib/thinking_sphinx/deltas.rb", "lib/thinking_sphinx/deploy/capistrano.rb", "lib/thinking_sphinx/facet.rb", "lib/thinking_sphinx/facet_collection.rb", "lib/thinking_sphinx/field.rb", "lib/thinking_sphinx/index/builder.rb", "lib/thinking_sphinx/index/faux_column.rb", "lib/thinking_sphinx/index.rb", "lib/thinking_sphinx/property.rb", "lib/thinking_sphinx/rails_additions.rb", "lib/thinking_sphinx/search/facets.rb", "lib/thinking_sphinx/search.rb", "lib/thinking_sphinx/source/internal_properties.rb", "lib/thinking_sphinx/source/sql.rb", "lib/thinking_sphinx/source.rb", "lib/thinking_sphinx/tasks.rb", "lib/thinking_sphinx.rb", "LICENCE", "README.textile", "tasks/distribution.rb", "tasks/testing.rb", "tasks/rails.rake", "vendor/after_commit", "vendor/after_commit/init.rb", "vendor/after_commit/lib", "vendor/after_commit/lib/after_commit", "vendor/after_commit/lib/after_commit/active_record.rb", "vendor/after_commit/lib/after_commit/connection_adapters.rb", "vendor/after_commit/lib/after_commit.rb", "vendor/after_commit/LICENSE", "vendor/after_commit/Rakefile", "vendor/after_commit/README", "vendor/after_commit/test", "vendor/after_commit/test/after_commit_test.rb", "vendor/delayed_job", "vendor/delayed_job/lib", "vendor/delayed_job/lib/delayed", "vendor/delayed_job/lib/delayed/job.rb", "vendor/delayed_job/lib/delayed/message_sending.rb", "vendor/delayed_job/lib/delayed/performable_method.rb", "vendor/delayed_job/lib/delayed/worker.rb", "vendor/riddle", "vendor/riddle/lib", "vendor/riddle/lib/riddle", "vendor/riddle/lib/riddle/client", "vendor/riddle/lib/riddle/client/filter.rb", "vendor/riddle/lib/riddle/client/message.rb", "vendor/riddle/lib/riddle/client/response.rb", "vendor/riddle/lib/riddle/client.rb", "vendor/riddle/lib/riddle/configuration", "vendor/riddle/lib/riddle/configuration/distributed_index.rb", "vendor/riddle/lib/riddle/configuration/index.rb", "vendor/riddle/lib/riddle/configuration/indexer.rb", "vendor/riddle/lib/riddle/configuration/remote_index.rb", "vendor/riddle/lib/riddle/configuration/searchd.rb", "vendor/riddle/lib/riddle/configuration/section.rb", "vendor/riddle/lib/riddle/configuration/source.rb", "vendor/riddle/lib/riddle/configuration/sql_source.rb", "vendor/riddle/lib/riddle/configuration/xml_source.rb", "vendor/riddle/lib/riddle/configuration.rb", "vendor/riddle/lib/riddle/controller.rb", "vendor/riddle/lib/riddle.rb", "spec/unit/thinking_sphinx/active_record/delta_spec.rb", "spec/unit/thinking_sphinx/active_record/has_many_association_spec.rb", "spec/unit/thinking_sphinx/active_record/search_spec.rb", "spec/unit/thinking_sphinx/active_record_spec.rb", "spec/unit/thinking_sphinx/association_spec.rb", "spec/unit/thinking_sphinx/attribute_spec.rb", "spec/unit/thinking_sphinx/collection_spec.rb", "spec/unit/thinking_sphinx/configuration_spec.rb", "spec/unit/thinking_sphinx/core/string_spec.rb", "spec/unit/thinking_sphinx/facet_collection_spec.rb", "spec/unit/thinking_sphinx/facet_spec.rb", "spec/unit/thinking_sphinx/field_spec.rb", "spec/unit/thinking_sphinx/index/builder_spec.rb", "spec/unit/thinking_sphinx/index/faux_column_spec.rb", "spec/unit/thinking_sphinx/index_spec.rb", "spec/unit/thinking_sphinx/rails_additions_spec.rb", "spec/unit/thinking_sphinx/search_spec.rb", "spec/unit/thinking_sphinx/source_spec.rb", "spec/unit/thinking_sphinx_spec.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://ts.freelancing-gods.com}
  s.post_install_message = %q{With the release of Thinking Sphinx 1.1.18, there is one important change to
note: previously, the default morphology for indexing was 'stem_en'. The new
default is nil, to avoid any unexpected behavior. If you wish to keep the old
value though, you will need to add the following settings to your
config/sphinx.yml file:

development:
  morphology: stem_en
test:
  morphology: stem_en
production:
  morphology: stem_en

To understand morphologies/stemmers better, visit the following link:
http://www.sphinxsearch.com/docs/manual-0.9.8.html#conf-morphology

}
  s.rdoc_options = ["--title", "Thinking Sphinx -- Rails/Merb Sphinx Plugin", "--line-numbers"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{thinking-sphinx}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A concise and easy-to-use Ruby library that connects ActiveRecord to the Sphinx search daemon, managing configuration, indexing and searching.}
  s.test_files = ["spec/unit/thinking_sphinx/active_record/delta_spec.rb", "spec/unit/thinking_sphinx/active_record/has_many_association_spec.rb", "spec/unit/thinking_sphinx/active_record/search_spec.rb", "spec/unit/thinking_sphinx/active_record_spec.rb", "spec/unit/thinking_sphinx/association_spec.rb", "spec/unit/thinking_sphinx/attribute_spec.rb", "spec/unit/thinking_sphinx/collection_spec.rb", "spec/unit/thinking_sphinx/configuration_spec.rb", "spec/unit/thinking_sphinx/core/string_spec.rb", "spec/unit/thinking_sphinx/facet_collection_spec.rb", "spec/unit/thinking_sphinx/facet_spec.rb", "spec/unit/thinking_sphinx/field_spec.rb", "spec/unit/thinking_sphinx/index/builder_spec.rb", "spec/unit/thinking_sphinx/index/faux_column_spec.rb", "spec/unit/thinking_sphinx/index_spec.rb", "spec/unit/thinking_sphinx/rails_additions_spec.rb", "spec/unit/thinking_sphinx/search_spec.rb", "spec/unit/thinking_sphinx/source_spec.rb", "spec/unit/thinking_sphinx_spec.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
