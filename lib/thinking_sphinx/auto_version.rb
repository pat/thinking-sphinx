module ThinkingSphinx
  class AutoVersion
    def self.detect
      version = ThinkingSphinx::Configuration.instance.version
      case version
      when '0.9.8', '0.9.9'
        require "riddle/#{version}"
      when '1.10-beta', '1.10-id64-beta', '1.10-dev'
        require 'riddle/1.10'
      else
        documentation_link = %Q{
For more information, read the documentation:
http://freelancing-god.github.com/ts/en/advanced_config.html          
}

        if version.nil? || version.empty?
          STDERR.puts %Q{
Sphinx cannot be found on your system. You may need to configure the following
settings in your config/sphinx.yml file:
  * bin_path
  * searchd_binary_name
  * indexer_binary_name

#{documentation_link}
}
        else
          STDERR.puts %Q{
Unsupported version: #{version}

#{documentation_link}
}
        end
      end
    end
  end
end
