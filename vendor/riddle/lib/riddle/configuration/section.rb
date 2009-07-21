module Riddle
  class Configuration
    class Section
      class << self
        attr_accessor :settings
      end
      
      settings = []
      
      def valid?
        true
      end
      
      private
      
      def settings_body
        self.class.settings.select { |setting|
          !send(setting).nil?
        }.collect { |setting|
          if send(setting) == ""
            conf = "  #{setting} = "
          else
            conf = setting_to_array(setting).collect { |set|
              "  #{setting} = #{set}"
            }
          end
          conf.length == 0 ? nil : conf
        }.flatten.compact
      end
      
      def setting_to_array(setting)
        value = send(setting)
        case value
        when Array      then value
        when TrueClass  then [1]
        when FalseClass then [0]
        else
          [value]
        end
      end
    end
  end
end
