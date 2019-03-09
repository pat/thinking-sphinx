# Changelog

All notable changes to this project (at least, from v3.0.0 onwards) are documented in this file.

## 4.2.0 - 2019-03-09

### Added

* Allow changing the default encoding for MySQL database connections from utf8 to something else via the `mysql_encoding` setting in `config/thinking_sphinx.yml`. In the next significant release, the default will change to utf8mb4 (which is supported in MySQL 5.5.3 and newer).
* Added Rails 6.0 and Manticore 2.8 to the test matrix.

### Changed

* Use Arel's SQL literals for generated order clauses, to avoid warnings from Rails 6.

### Fixed

* Fix usage of alternative primary keys in update and deletion callbacks and attribute access.
* Ensure `respond_to?` takes Sphinx scopes into account ([Jonathan del Strother](https://github.com/jdelstrother) in [#1124](https://github.com/pat/thinking-sphinx/pull/1124)).
* Add `:excerpts` as a known option for search requests.
* Fix depolymorphed association join construction with Rails 6.0.0.beta2.
* Reset ThinkingSphinx::Configuration's cached values when Rails reloads, to avoid holding onto stale references to ActiveRecord models ([#1125](https://github.com/pat/thinking-sphinx/issues/1125)).
* Don't join against associations in `sql_query` if they're only used by query-sourced properties ([Hans de Graaff](https://github.com/graaff) in [#1127](https://github.com/pat/thinking-sphinx/pull/1127)).

## 4.1.0 - 2018-12-28

[Release Notes](https://github.com/pat/thinking-sphinx/releases/tag/v4.1.0)

### Added

* The `:sql` search option can now accept per-model settings with model names as keys. e.g. `ThinkingSphinx.search "foo", :sql => {'Article' => {:include => :user}}` (Sergey Malykh in [#1120](https://github.com/pat/thinking-sphinx/pull/1120)).

### Changed

* Drop MRI 2.2 from the test matrix, and thus no longer officially supported (though the code will likely continue to work with 2.2 for a while).
* Added MRI 2.6, Sphinx 3.1 and Manticore 2.7 to the test matrix.

### Fixed

* Real-time indices now work with non-default integer primary keys (alongside UUIDs or other non-integer primary keys).

## 4.0.0 - 2018-04-10

[Release Notes](https://github.com/pat/thinking-sphinx/releases/tag/v4.0.0)

### Added

* Support Sphinx 3.0.
* Allow disabling of docinfo setting via `skip_docinfo: true` in `config/thinking_sphinx.yml`.
* Support merging of delta indices into their core counterparts using ts:merge.
* Support UNIX sockets as an alternative for TCP connections to the daemon (MRI-only).
* Translate relative paths to absolute when generating configuration when `absolute_paths: true` is set per environment in `config/thinking_sphinx.yml`.

### Changed

* Drop Sphinx 2.0 support.
* Drop auto-typing of filter values.
* INDEX_FILTER environment variable is applied when running ts:index on SQL-backed indices.
* Drop MRI 2.0/2.1 support.
* Display a useful error message if processing real-time indices but the daemon isn't running.
* Refactor interface code into separate command classes, and allow for a custom rake interface.
* Add frozen_string_literal pragma comments.
* Log exceptions when processing real-time indices, but don't stop.
* Update polymorphic properties to support Rails 5.2.
* Allow configuration of the index guard approach.
* Output a warning if guard files exist when calling ts:index.
* Delete index guard files as part of ts:rebuild and ts:clear.

### Fixed

* Handle situations where no exit code is provided for Sphinx binary calls.
* Don't attempt to interpret indices for models that don't have a database table.

## 3.4.2 - 2017-09-29

[Release Notes](https://github.com/pat/thinking-sphinx/releases/tag/v3.4.2)

### Changed

* Allow use of deletion callbacks for rollback events.
* Remove extra deletion code in the Populator - it's also being done by the real-time rake interface.

### Fixed

* Real-time callback syntax for namespaced models accepts a string (as documented).
* Fix up logged warnings.
* Add missing search options to known values to avoid incorrect warnings.

## 3.4.1 - 2017-08-29

[Release Notes](https://github.com/pat/thinking-sphinx/releases/tag/v3.4.1)

### Changed

* Treat "Lost connection to MySQL server" as a connection error (Manuel Schnitzer).

### Fixed

* Index normalisation will now work even when index model tables don't exist.

## 3.4.0 - 2017-08-28

[Release Notes](https://github.com/pat/thinking-sphinx/releases/tag/v3.4.0)

### Added

* Rake tasks are now unified, so the original tasks will operate on real-time indices as well.
* Output warnings when unknown options are used in search calls.
* Allow generation of a single real-time index (Tim Brown).
* Automatically use UTF8 in Sphinx for encodings that are extensions of UTF8.
* Basic type checking for attribute filters.

### Changed

* Delta callback logic now prioritises checking for high level settings rather than model changes.
* Allow for unsaved records when calculating document ids (and return nil).
* Display SphinxQL deletion statements in the log.
* Add support for Ruby's frozen string literals feature.
* Use saved_changes if it's available (in Rails 5.1+).
* Set a default connection timeout of 5 seconds.
* Don't search multi-table inheritance ancestors.
* Handle non-computable queries as parse errors.

### Fixed

* Index normalisation now occurs consistently, and removes unneccesary sphinx_internal_class_name fields from real-time indices.
* Fix Sphinx connections in JRuby.
* Fix long SphinxQL query handling in JRuby.
* Always close the SphinxQL connection if Innertube's asking (@cmaion).
* Get bigint primary keys working in Rails 5.1.
* Fix handling of attached starts of Sphinx (via Henne Vogelsang).
* Fix multi-field conditions.
* Use the base class of STI models for polymorphic join generation (via Andrés Cirugeda).
* Ensure ts:index now respects rake silent/quiet flags.

## 3.3.0 - 2016-12-13

[Release Notes](https://github.com/pat/thinking-sphinx/releases/tag/v3.3.0)

### Added

* Real-time callbacks can now be used with after_commit hooks if that's preferred over after_save.
* Allow for custom batch sizes when populating real-time indices.

### Changed

* Only toggle the delta value if the record has changed or is new (rather than on every single save call).
* Delta indexing is now quiet by default (rather than verbose).
* Use Riddle's reworked command interface for interacting with Sphinx's command-line tools.
* Respect Rake's quiet and silent flags for the Thinking Sphinx rake tasks.
* ts:start and ts:stop tasks default to verbose.
* Sort engine paths for loading indices to ensure they're consistent.
* Custom exception class for invalid database adapters.
* Memoize the default primary keys per context.

### Fixed

* Explicit source method in the SQLQuery Builder instead of relying on method missing, thus avoiding any global methods named 'source' (Asaf Bartov).
* Load indices before deleting index files, to ensure the files are actually found and deleted.
* Avoid loading ActiveRecord earlier than necessary. This avoids loading Rails out of order, which caused problems with Rails 5.
* Handle queries that are too long for Sphinx.
* Improve Rails 5 / JRuby support.
* Fixed handling of multiple field tokens in wildcarding logic.
* Ensure custom primary key columns are handled consistently (Julio Monteiro).

## 3.2.0 - 2016-05-13

[Release Notes](https://github.com/pat/thinking-sphinx/releases/tag/v3.2.0)

### Added

* Add JSON attribute support for real-time indices.
* Add ability to disable *all* Sphinx-related callbacks via ThinkingSphinx::Callbacks.suspend! and ThinkingSphinx::Callbacks.resume!. Particularly useful for unit tests.
* Add native OutOfBoundsError for search queries outside the pagination bounds.
* Support MySQL SSL options on a per-index level (@arrtchiu).
* Allow for different indexing strategies (e.g. all at once, or one by one).
* Allow rand_seed as a select option (Mattia Gheda).
* Add primary_key option for index definitions (Nathaneal Gray).
* Add ability to start searchd in the foreground (Andrey Novikov).

### Changed

* Improved error messages for duplicate property names and missing columns.
* Don't populate search results when requesting just the count values (Andrew Roth).
* Reset delta column before core indexing begins (reverting behaviour introduced in 3.1.0). See issue #958 for further discussion.
* Use Sphinx's bulk insert ability (Chance Downs).
* Reduce memory/object usage for model references (Jonathan del Strother).
* Disable deletion callbacks when real-time indices are in place and all other real-time callbacks are disabled.
* Only use ERB to parse the YAML file if ERB is loaded.

### Fixed

* Ensure SQL table aliases are reliable for SQL-backed index queries.
* Fixed mysql2 compatibility for memory references (Roman Usherenko).
* Fixed JRuby compatibility with camelCase method names (Brandon Dewitt).
* Fix stale id handling for multiple search contexts (Jonathan del Strother).
* Handle quoting of namespaced tables (Roman Usherenko).
* Make preload_indices thread-safe.
* Improved handling of marshalled/demarshalled search results.

## 3.1.4 - 2015-06-01

[Release Notes](https://github.com/pat/thinking-sphinx/releases/tag/v3.1.4)

### Added

* Add JSON as a Sphinx type for attributes (Daniel Vandersluis).
* minimal_group_by? can now be set in config/thinking_sphinx.yml to automatically apply to all index definitions.

### Changed

* Add a contributor code of conduct.
* Remove polymorphic association and HABTM query support (when related to Thinking Sphinx) when ActiveRecord 3.2 is involved.
* Remove default charset_type - no longer required for Sphinx 2.2.
* Removing sql_query_info setting, as it's no longer used by Sphinx (nor is it actually used by Thinking Sphinx).

### Fixed

* Kaminari expects prev_page to be available.
* Don't try to delete guard files if they don't exist (@exAspArk).
* Handle database settings reliably, now that ActiveRecord 4.2 uses strings all the time.
* More consistent with escaping table names.
* Bug fix for association creation (with polymophic fields/attributes).

## 3.1.3 - 2015-01-21

[Release Notes](https://github.com/pat/thinking-sphinx/releases/tag/v3.1.3)

### Added

* Allow for custom offset references with the :offset_as option - thus one model across many schemas with Apartment can be treated differently.
* Allow for custom IndexSet classes.

### Changed

* Log excerpt SphinxQL queries just like the search queries.
* Load Railtie if Rails::Railtie is defined, instead of just Rails (Andrew Cone).
* Convert raw Sphinx results to an array when querying (Bryan Ricker).
* Add bigint support for real-time indices, and use bigints for the sphinx_internal_id attribute (mapped to model primary keys) (Chance Downs).

### Fixed

* Generate de-polymorphised associations properly for Rails 4.2
* Use reflect_on_association instead of reflections, to stick to the public ActiveRecord::Base API.
* Don't load ActiveRecord early - fixes a warning in Rails 4.2.
* Don't double-up on STI filtering, already handled by Rails.

## 3.1.2 - 2014-11-04

[Release Notes](https://github.com/pat/thinking-sphinx/releases/tag/v3.1.2)

### Added

* Allow for custom paths for index files using :path option in the ThinkingSphinx::Index.define call.
* Allow the binlog path to be an empty string (Bobby Uhlenbrock).
* Add status task to report on whether Sphinx is running.
* Real-time index callbacks can take a block for dynamic scoping.
* Allow casting of document ids pre-offset as bigints (via big_documents_id option).

### Changed

* regenerate task now only deletes index files for real-time indices.
* Raise an exception when a populated search query is modified (as it can't be requeried).
* Log indices that aren't processed due to guard files existing.
* Paginate records by 1000 results at a time when flagging as deleted.
* Default the Capistrano TS Rails environment to use rails_env, and then fall back to stage.
* rebuild task uses clear between stopping the daemon and indexing.

### Fixed

* Ensure indexing guard files are removed when an exception is raised (Bobby Uhlenbrock).
* Don't update real-time indices for objects that are not persisted (Chance Downs).
* Use STI base class for polymorphic association replacements.
* Convert database setting keys to symbols for consistency with Rails (@dimko).
* Field weights and other search options are now respected from set_property.
* Models with more than one index have correct facet counts (using Sphinx 2.1.x or newer).
* Some association fixes for Rails 4.1.
* Clear connections when raising connection errors.

## 3.1.1 - 2014-04-22

[Release Notes](https://github.com/pat/thinking-sphinx/releases/tag/v3.1.1)

### Added

* Allow for common section in generated Sphinx configuration files for Sphinx 2.2.x (disabled by default, though) (Trevor Smith).
* Basic support for HABTM associations and MVAs with query/ranged-query sources.
* Real-time indices callbacks can be disabled (useful for unit tests).
* ThinkingSphinx::Test has a clear method and no-index option for starting for real-time setups.
* Allow disabling of distributed indices.

### Changed

* Include full statements when query execution errors are raised (uglier, but more useful when debugging).
* Connection error messages now mention Sphinx, instead of just MySQL.
* Raise an exception when a referenced column does not exist.
* Capistrano tasks use thinking_sphinx_rails_env (defaults to standard environment) (Robert Coleman).
* Alias group and count columns for easier referencing in other clauses.
* Log real-time index updates (Demian Ferreiro).
* All indices now respond to a public attributes method.

### Fixed

* Don't apply attribute-only updates to real-time indices.
* Don't instantiate blank strings (via inheritance type columns) as constants.
* Don't presume all indices for a model have delta pairs, even if one does.
* Always use connection options for connection information.
* respond_to? works reliably with masks (Konstantin Burnaev).
* Avoid null values in MVA query/ranged-query sources.
* Don't send unicode null characters to real-time Sphinx indices.
* :populate option is now respected for single-model searches.
* :thinking_sphinx_roles is now used consistently in Capistrano v3 tasks.
* Only expand log directory if it exists.
* Handle JDBC connection errors appropriately (Adam Hutchison).
* Fixing wildcarding of Unicode strings.
* Improved handling of association searches with real-time indices, including via has_many :though associations (Rob Anderton).

## 3.1.0 - 2014-01-11

[Release Notes](https://github.com/pat/thinking-sphinx/releases/tag/v3.1.0)

### Added

* Support for Capistrano v3 (Alexander Tipugin).
* JRuby support (with Sphinx 2.1 or newer).
* Support for Sphinx 2.2.x's HAVING and GROUP N BY SphinxQL options.
* Adding max_predicted_time search option (Sphinx 2.2.x).
* Wildcard/starring can be applied directly to strings using ThinkingSphinx::Query.wildcard('pancakes'), and escaping via ThinkingSphinx::Query.escape('pancakes').
* Capistrano recipe now includes tasks for realtime indices.
* :group option within :sql options in a search call is passed through to the underlying ActiveRecord relation (Siarhei Hanchuk).
* Persistent connections can be disabled if you wish.
* Track what's being indexed, and don't double-up while indexing is running. Single indices (e.g. deltas) can be processed while a full index is happening, though.
* Pass through :delta_options to delta processors (Timo Virkalla).
* All delta records can have their core pairs marked as deleted after a suspended delta (use ThinkingSphinx::Deltas.suspend_and_update instead of ThinkingSphinx::Deltas.suspend).
* Set custom database settings within the index definition, using the set_database method. A more sane approach with multiple databases.

### Changed

* Updating Riddle requirement to >= 1.5.10.
* Extracting join generation into its own gem: Joiner.
* Geodist calculation is now prepended to the SELECT statement, so it can be referred to by other dynamic attributes.
* Auto-wildcard/starring (via :star => true) now treats escaped characters as word separators.
* Capistrano recipe no longer automatically adds thinking_sphinx:index and thinking_sphinx:start to be run after deploy:cold.
* UTF-8 forced encoding is now disabled by default (in line with Sphinx 2.1.x).
* Sphinx functions are now the default, instead of the legacy special variables (in line with Sphinx 2.1.x).
* Rails 3.1 is no longer supported.
* MRI 1.9.2 is no longer supported.
* Insist on at least * for SphinxQL SELECT statements.
* Reset the delta column to true after core indexing is completed, instead of before, and don't filter out delta records from the core source.
* Provide a distributed index per model that covers both core and delta indices.

### Fixed

* Indices will be detected in Rails engines upon configuration.
* Destroy callbacks are ignored for non-persisted objects.
* Blank STI values are converted to the parent class in Sphinx index data (Jonathan Greenberg).
* Track indices on parent STI models when marking documents as deleted.
* Separate per_page/max_matches values are respected in facet searches (Timo Virkkala).
* Don't split function calls when casting timestamps (Timo Virkalla).

## 3.0.6 - 2013-10-20

[Release Notes](https://github.com/pat/thinking-sphinx/releases/tag/v3.0.6)

### Added

* Raise an error if no indices match the search criteria (Bryan Ricker).
* skip_time_zone setting is now available per environment via config/thinking_sphinx.yml to avoid the sql_query_pre time zone command.
* Added new search options in Sphinx 2.1.x.
* Added ability to disable UTF-8 forced encoding, now that Sphinx 2.1.2 returns UTF-8 strings by default. This will be disabled by default in Thinking Sphinx 3.1.0.
* Added ability to switch between Sphinx special variables and the equivalent functions. Sphinx 2.1.x requires the latter, and that behaviour will become the default in Sphinx 3.1.0.
* Adding search_for_ids on scoped search calls.
* MySQL users can enable a minimal GROUP BY statement, to speed up queries: set_property :minimal_group_by? => true.

### Changed

* Updating Riddle dependency to be >= 1.5.9.
* Separated directory preparation from data generation for real-time index (re)generation tasks.
* Have tests index UTF-8 characters where appropriate (Pedro Cunha).
* Always use DISTINCT in group concatenation.
* Sphinx connection failures now have their own class, ThinkingSphinx::ConnectionError, instead of the standard Mysql2::Error.
* Don't clobber custom :select options for facet searches (Timo Virkkala).
* Automatically load Riddle's Sphinx 2.0.5 compatability changes.
* Realtime fields and attributes now accept symbols as well as column objects, and fields can be sortable (with a _sort prefix for the matching attribute).
* Insist on the log directory existing, to ensure correct behaviour for symlinked paths. (Michael Pearson).
* Rake's silent mode is respected for indexing (@endoscient).

### Fixed

* Cast every column to a timestamp for timestamp attributes with multiple columns.
* Don't use Sphinx ordering if SQL order option is supplied to a search.
* Custom middleware and mask options now function correctly with model-scoped searches.
* Suspended deltas now no longer update core indices as well.
* Use alphabetical ordering for index paths consistently (@grin).
* Convert very small floats to fixed format for geo-searches.

## 3.0.5 - 2013-08-26

### Added

* Allow scoping of real-time index models.

### Changed

* Updating Riddle dependency to be >= 1.5.8.
* Real-time index population presentation and logic are now separated.
* Using the connection pool for update callbacks, excerpts, deletions.
* Don't add the sphinx_internal_class_name unless STI models are indexed.
* Use Mysql2's reconnect option and have it turned on by default.
* Improved auto-starring with escaped characters.

### Fixed

* Respect existing sql_query_range/sql_query_info settings.
* Don't add select clauses or joins to sql_query if they're for query/ranged-query properties.
* Set database timezones as part of the indexing process.
* Chaining scopes with just options works again.

## 3.0.4 - 2013-07-09

### Added

* ts:regenerate rake task for rebuilding Sphinx when realtime indices are involved.
* ts:clear task removes all Sphinx index and binlog files.
* Facet search calls now respect the limit option (which otherwise defaults to max_matches) (Demian Ferreiro).
* Excerpts words can be overwritten with the words option (@groe).
* The :facets option can be used in facet searches to limit which facets are queried.
* A separate role can be set for Sphinx actions with Capistrano (Andrey Chernih).
* Facet searches can now be called from Sphinx scopes.

### Changed

* Updating Riddle dependency to be >= 1.5.7.
* Glaze now responds to respond_to? (@groe).
* Deleted ActiveRecord objects are deleted in realtime indices as well.
* Realtime callbacks are no longer automatically added, but they're now more flexible (for association situations).
* Cleaning and refactoring so Code Climate ranks this as A-level code (Philip Arndt, Shevaun Coker, Garrett Heinlen).
* Exceptions raised when communicating with Sphinx are now mentioned in the logs when queries are retried (instead of STDOUT).
* Excerpts now use just the query and standard conditions, instead of parsing Sphinx's keyword metadata (which had model names in it).
* Get database connection details from ActiveRecord::Base, not each model, as this is where changes are reflected.
* Default Sphinx scopes are applied to new facet searches.

### Fixed

* Empty queries with the star option set to true are handled gracefully.
* Excerpts are now wildcard-friendly.
* Facet searches now use max_matches value (with a default of 1000) to ensure as many results as possible are returned.
* The settings cache is now cleared when the configuration singleton is reset (Pedro Cunha).
* Escaped @'s in queries are considered part of each word, instead of word separators.
* Internal class name conditions are ignored with auto-starred queries.
* RDoc doesn't like constant hierarchies split over multiple lines.

## 3.0.3 - 2013-05-07

### Added

* INDEX_ONLY environment flag is passed through when invoked through Capistrano (Demian Ferreiro).
* use_64_bit option returns as cast_to_timestamp instead (Denis Abushaev).
* Collection of hooks (lambdas) that get called before indexing. Useful for delta libraries.

### Changed

* Updating Riddle dependency to be >= 1.5.6
* Delta jobs get common classes to allow third-party delta behaviours to leverage Thinking Sphinx.
* Raise ThinkingSphinx::MixedScopesError if a search is called through an ActiveRecord scope.
* GroupEnumeratorsMask is now a default mask, as masks need to be in place before search results are populated/the middleware is called (and previously it was being added within a middleware call).
* The current_page method is now a part of ThinkingSphinx::Search, as it is used when populating results.

### Fixed

* Update to association handling for Rails/ActiveRecord 4.0.0.rc1.
* Cast and concatenate multi-column attributes correctly.
* Don't load fields or attributes when building a real-time index - otherwise the index is translated before it has a chance to be built.
* Default search panes are cloned for each search.
* Index-level settings (via set_property) are now applied consistently after global settings (in thinking_sphinx.yml).
* All string values returned from Sphinx are now properly converted to UTF8.
* The default search masks are now cloned for each search, instead of referring to the constant (and potentially modifying it often).

## 3.0.2 - 2013-03-23

### Added

* Ruby 2.0 support.
* Rails 4.0.0 beta1 support.
* Indexes defined in app/indices in engines are now loaded (Antonio Tapiador del Dujo).
* Query errors are classified as such, instead of getting the base SphinxError.

### Changed

* per_page now accepts an optional paging limit, to match WillPaginate's behaviour. If none is supplied, it just returns the page size.
* Strings and regular expressions in ThinkingSphinx::Search::Query are now treated as UTF-8.
* Setting a custom framework will rebuild the core configuration around its provided settings (path and environment).
* Search masks don't rely on respond_to?, and so Object/Kernel methods are passed through to the underlying array instead.
* Empty search conditions are now ignored, instead of being appended with no value (Nicholas Klick).
* Custom conditions are no longer added to the sql_query_range value, as they may involve associations.

### Fixed

* :utf8? option within index definitions is now supported, and defaults to true if the database configuration's encoding is set to 'utf8'.
* indices_location and configuration_file values in thinking_sphinx.yml will be applied to the configuration.
* Primary keys that are not 'id' now work correctly.
* Search options specified in index definitions and thinking_sphinx.yml are now used in search requests (eg: max_matches, field_weights).
* Custom association conditions are no longer presumed to be an array.
* Capistrano tasks use the correct ts rake task prefix (David Celis).

## 3.0.1 - 2013-02-04

### Added

* Provide Capistrano deployment tasks (David Celis).
* Allow specifying of Sphinx version. Is only useful for Flying Sphinx purposes at this point - has no impact on Riddle or Sphinx.
* Support new JDBC configuration style (when JDBC can be used) (Kyle Stevens).
* Mysql2::Errors are wrapped as ThinkingSphinx::SphinxErrors, with subclasses of SyntaxError and ParseError used appropriately. Syntax and parse errors do not prompt a retry on a new connection.
* Polymorphic associations can be used within index definitions when the appropriate classes are set out.
* Allow custom strings for SQL joins in index definitions.
* indexer and searchd settings are added to the appropriate objects from config/thinking_sphinx.yml (@ygelfand).

### Changed

* Use connection pool for search queries. If a query fails, it will be retried on a new connection before raising if necessary.
* Glaze always passes methods through to the underlying ActiveRecord::Base object if they don't exist on any of the panes.

### Fixed

* Referring to associations via polymorphic associations in an index definition now works.
* Don't override foreign keys for polymorphic association replacements.
* Quote namespaced model names in class field condition.
* New lines are maintained and escaped in custom source queries.
* Subclasses of indexed models fire delta callbacks properly.
* Thinking Sphinx can be loaded via thinking/sphinx, to satisfy Bundler.
* New lines are maintained and escaped in sql_query values.

## 3.0.0 - 2013-01-02

### Added

* Initial realtime index support, including the ts:generate task for building index datasets. Sphinx 2.0.6 is required.
* SphinxQL connection pooling via the Innertube gem.

### Changed

* Updating Riddle dependency to 1.5.4.
* UTF-8 is now the default charset again (as it was in earlier Thinking Sphinx versions).
* Removing ts:version rake task.

### Fixed

* Respect source options as well as underlying settings via the set_property method in index definitions.
* Load real-time index definitions when listing fields, attributes, and/or conditions.

## 3.0.0.rc - 2012-12-22

### Added

* Source type support (query and ranged query) for both attributes and fields. Custom SQL strings can be supplied as well.
* Wordcount attributes and fields now supported.
* Support for Sinatra and other non-Rails frameworks.
* A sphinx scope can be defined as the default.
* An index can have multiple sources, by using define_source within the index definition.
* sanitize_sql is available within an index definition.
* Providing :prefixes => true or :infixes => true as an option when declaring a field means just the noted fields have infixes/prefixes applied.
* ThinkingSphinx::Search#query_time returns the time Sphinx took to make the query.
* Namespaced model support.
* Default settings for index definition arguments can be set in config/thinking_sphinx.yml.
* A custom Riddle/Sphinx controller can be supplied. Useful for Flying Sphinx to have an API layer over Sphinx commands, without needing custom gems for different Thinking Sphinx/Flying Sphinx combinations.

### Fixed

* Correctly escape nulls in inheritance column (Darcy Laycock).
* Use ThinkingSphinx::Configuration#render_to_file instead of ThinkingSphinx::Configuration#build in test helpers (Darcy Laycock).
* Suppressing delta output in test helpers now works (Darcy Laycock).

## 3.0.0.pre - 2012-10-06

First pre-release of v3. Not quite feature complete, but the important stuff is certainly covered. See the README for more the finer details.
