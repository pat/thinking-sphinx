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
        value.is_a?(Array) ? value : [value]
      end
    end
  end
end
