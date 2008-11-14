module Riddle
  class Configuration
    class Index < Riddle::Configuration::Section
      self.settings = [:source, :path, :docinfo, :mlock, :morphology,
        :stopwords, :wordforms, :exceptions, :min_word_len, :charset_type,
        :charset_table, :ignore_chars, :min_prefix_len, :min_infix_len,
        :prefix_fields, :infix_fields, :enable_star, :ngram_len, :ngram_chars,
        :phrase_boundary, :phrase_boundary_step, :html_strip,
        :html_index_attrs, :html_remove_elements, :preopen]
      
      attr_accessor :name, :parent, :sources, :path, :docinfo, :mlock,
        :morphologies, :stopword_files, :wordform_files, :exception_files,
        :min_word_len, :charset_type, :charset_table, :ignore_characters,
        :min_prefix_len, :min_infix_len, :prefix_field_names,
        :infix_field_names, :enable_star, :ngram_len, :ngram_characters,
        :phrase_boundaries, :phrase_boundary_step, :html_strip,
        :html_index_attrs, :html_remove_element_tags, :preopen
      
      def initialize(name, *sources)
        @name                     = name
        @sources                  = sources
        @morphologies             = []
        @stopword_files           = []
        @wordform_files           = []
        @exception_files          = []
        @ignore_characters        = []
        @prefix_field_names       = []
        @infix_field_names        = []
        @ngram_characters         = []
        @phrase_boundaries        = []
        @html_remove_element_tags = []
      end
      
      def source
        @sources.collect { |s| s.name }
      end
      
      def morphology
        @morphologies.join(", ")
      end
      
      def stopwords
        @stopword_files.join(" ")
      end
      
      def wordforms
        @wordform_files.join(" ")
      end
      
      def exceptions
        @exception_files.join(" ")
      end
      
      def ignore_chars
        @ignore_characters.join(", ")
      end
      
      def prefix_fields
        @prefix_field_names.join(", ")
      end
      
      def infix_fields
        @infix_field_names.join(", ")
      end
      
      def ngram_chars
        @ngram_characters.join(", ")
      end
      
      def phrase_boundary
        @phrase_boundaries.join(", ")
      end
      
      def html_remove_elements
        @html_remove_element_tags.join(", ")
      end
      
      def render
        raise ConfigurationError unless valid?
        
        inherited_name = "#{name}"
        inherited_name << " : #{parent}" if parent
        (
          @sources.collect { |s| s.render } +
          ["index #{inherited_name}", "{"] +
          settings_body +
          ["}", ""]
        ).join("\n")
      end
      
      def valid?
        (!@name.nil?) && (!( @sources.length == 0 || @path.nil? ) || !@parent.nil?)
      end
    end
  end
end