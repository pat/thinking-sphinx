module Riddle
  class Configuration
    class Searchd
      def valid?
        set_listen
        clear_deprecated
        
        !( @listen.nil? || @pid_file.nil? )
      end
      
      private
      
      def set_listen
        return unless @listen.nil?
        
        @listen = @port.to_s if @port && @address.nil?
        @listen = "#{@address}:#{@port}" if @address && @port
      end
      
      def clear_deprecated
        return if @listen.nil?
        
        @address  = nil
        @port     = nil
      end
    end
  end
end