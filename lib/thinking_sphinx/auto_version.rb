module ThinkingSphinx
  class AutoVersion
    def self.detect
      version = ThinkingSphinx::Configuration.instance.controller.sphinx_version
      case version
      when '0.9.8', '0.9.9'
        require "riddle/#{version}"
      else
        STDERR.puts %Q{
Sphinx cannot be found on your system. You may need to configure the following
settings in your config/sphinx.yml file:
  * bin_path
  * searchd_binary_name
  * indexer_binary_name

For more information, read the documentation:
http://freelancing-god.github.com/ts/en/advanced_config.html
}
      end
    end
  end
end
