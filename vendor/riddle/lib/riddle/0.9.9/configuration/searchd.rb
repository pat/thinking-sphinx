module Riddle
  class Configuration
    class Searchd
      def valid?
        set_listen
        clear_deprecated

        !( @listen.nil? || @listen.empty? || @pid_file.nil? )
      end

      private

      def set_listen
        @listen = @listen.to_s if @listen.is_a?(Fixnum)

        return unless @listen.nil? || @listen.empty?

        @listen = []
        @listen << @port.to_s if @port
        @listen << "9306:mysql41" if @mysql41.is_a?(TrueClass)
        @listen << "#{@mysql41}:mysql41" if @mysql41.is_a?(Fixnum)

        @listen.each { |l| l.insert(0, "#{@address}:") } if @address
      end

      def clear_deprecated
        return if @listen.nil?

        @address  = nil
        @port     = nil
      end
    end
  end
end
