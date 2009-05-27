puts <<-MESSAGE
With the release of Thinking Sphinx 1.1.18, there is one important change to
note: previously, the default morphology for indexing was 'stem_en'. The new
default is nothing, to avoid any unexpected behavior. If you wish to keep the
old value though, you will need to add the following settings to your
config/sphinx.yml file:

development:
  morphology: stem_en
test:
  morphology: stem_en
production:
  morphology: stem_en

To understand morphologies/stemmers better, visit the following link:
http://www.sphinxsearch.com/docs/manual-0.9.8.html#conf-morphology

MESSAGE