module Riddle
  class Configuration
    class Index < Riddle::Configuration::Section
      def self.settings
        [
          :type, :source, :path, :docinfo, :mlock, :morphology,
          :dict, :index_sp, :index_zones, :min_stemming_len, :stopwords,
          :wordforms, :exceptions, :min_word_len, :charset_dictpath,
          :charset_type, :charset_table, :ignore_chars, :min_prefix_len,
          :min_infix_len, :prefix_fields, :infix_fields, :enable_star,
          :expand_keywords, :ngram_len, :ngram_chars, :phrase_boundary,
          :phrase_boundary_step, :blend_chars, :blend_mode, :html_strip,
          :html_index_attrs, :html_remove_elements, :preopen, :ondisk_dict,
          :inplace_enable, :inplace_hit_gap, :inplace_docinfo_gap,
          :inplace_reloc_factor, :inplace_write_factor, :index_exact_words,
          :overshort_step, :stopwords_step, :hitless_words
        ]
      end

      attr_accessor :name, :parent, :type, :sources, :path, :docinfo, :mlock,
        :morphologies, :dict, :index_sp, :index_zones, :min_stemming_len,
        :stopword_files, :wordform_files, :exception_files, :min_word_len,
        :charset_dictpath, :charset_type, :charset_table, :ignore_characters,
        :min_prefix_len, :min_infix_len, :prefix_field_names,
        :infix_field_names, :enable_star, :expand_keywords, :ngram_len,
        :ngram_characters, :phrase_boundaries, :phrase_boundary_step,
        :blend_chars, :blend_mode, :html_strip, :html_index_attrs,
        :html_remove_element_tags, :preopen, :ondisk_dict, :inplace_enable,
        :inplace_hit_gap, :inplace_docinfo_gap, :inplace_reloc_factor,
        :inplace_write_factor, :index_exact_words, :overshort_step,
        :stopwords_step, :hitless_words

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
        nil_join @morphologies, ", "
      end

      def morphology=(morphology)
        @morphologies = nil_split morphology, /,\s?/
      end

      def stopwords
        nil_join @stopword_files, " "
      end

      def stopwords=(stopwords)
        @stopword_files = nil_split stopwords, ' '
      end

      def wordforms
        nil_join @wordform_files, " "
      end

      def wordforms=(wordforms)
        @wordform_files = nil_split wordforms, ' '
      end

      def exceptions
        nil_join @exception_files, " "
      end

      def exceptions=(exceptions)
        @exception_files = nil_split exceptions, ' '
      end

      def ignore_chars
        nil_join @ignore_characters, ", "
      end

      def ignore_chars=(ignore_chars)
        @ignore_characters = nil_split ignore_chars, /,\s?/
      end

      def prefix_fields
        nil_join @prefix_field_names, ", "
      end

      def prefix_fields=(fields)
        if fields.is_a?(Array)
          @prefix_field_names = fields
        else
          @prefix_field_names = fields.split(/,\s*/)
        end
      end

      def infix_fields
        nil_join @infix_field_names, ", "
      end

      def infix_fields=(fields)
        if fields.is_a?(Array)
          @infix_field_names = fields
        else
          @infix_field_names = fields.split(/,\s*/)
        end
      end

      def ngram_chars
        nil_join @ngram_characters, ", "
      end

      def ngram_chars=(ngram_chars)
        @ngram_characters = nil_split ngram_chars, /,\s?/
      end

      def phrase_boundary
        nil_join @phrase_boundaries, ", "
      end

      def phrase_boundary=(phrase_boundary)
        @phrase_boundaries = nil_split phrase_boundary, /,\s?/
      end

      def html_remove_elements
        nil_join @html_remove_element_tags, ", "
      end

      def html_remove_elements=(html_remove_elements)
        @html_remove_element_tags = nil_split html_remove_elements, /,\s?/
      end

      def render
        raise ConfigurationError, "#{@name} #{@sources.inspect} #{@path} #{@parent}" unless valid?

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

      private

      def nil_split(string, pattern)
        (string || "").split(pattern)
      end

      def nil_join(array, delimiter)
        if array.length == 0
          nil
        else
          array.join(delimiter)
        end
      end
    end
  end
end
