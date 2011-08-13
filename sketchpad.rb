# LOADING ALL CLASSES is invoked by:
# - call define_index
#   - loading any model with an index definition
#   - because need to add to list of which models have indices.
# - sphinx document id for an instance is requested
#   - updating attributes
#   - toggling as deleted
# - when generating configuration
#   - need to build full configuration file.
# - when loading models_by_crc
#   - searches and facet searches pre Sphinx 2
# - facet search
# - search
#
# WHY?
# - need to know which classes are searchable
# - need to track number of indices (multiplier) - STI matters here
#   - are a subclass and superclass STI pair both indexed? One offset for both.
# - need to track position of current model within all indexed models (offset)
# - need to generate configuration
#
# SO:
# - load all indices *and* related models when needing document id
# - load all indices *and* related models when generating configuration
# - maybe can avoid loading all indices and/or related models when searching?
#   - would need to track ancestor models - harder when no multi-string
#     attributes - for filtering on classes. Can we be smart about this and
#     only force a full model load if absolutely necessary? And/or forced by
#     a flag so developers need to request it?



# Use symbols - avoid loading classes until we need to.
ThinkingSphinx.define_index_for :article do
  indexes subject, content
  indexes user.name, :as => :user_name

  has user_id
end

# Or better - let's not add everything to the root of TS module, and make it
# clear of the index driver.
ThinkingSphinx::Index.define :article, :with => :active_record do
  indexes subject, content
  indexes user.name, :as => :user_name

  has user_id
end

# Built-in index driver support could be auto-mapped to methods:
ThinkingSphinx::Index.define_with_active_record, :article

ThinkingSphinx::Index.define_with_realtime :article do
  indexes :subject, :content, :user_name

  has user_id => :integer
end
