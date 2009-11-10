module Riddle
  class Client
    class Filter
      attr_accessor :attribute, :values, :exclude
  
      # Attribute name, values (which can be an array or a range), and whether
      # the filter should be exclusive.
      def initialize(attribute, values, exclude=false)
        @attribute, @values, @exclude = attribute, values, exclude
      end
  
      def exclude?
        self.exclude
      end
  
      # Returns the message for this filter to send to the Sphinx service
      def query_message
        message = Message.new
    
        message.append_string self.attribute.to_s
        case self.values
        when Range
          if self.values.first.is_a?(Float) && self.values.last.is_a?(Float)
            message.append_int FilterTypes[:float_range]
            message.append_floats self.values.first, self.values.last
          else
            message.append_int FilterTypes[:range]
            append_integer_range message, self.values
          end
        when Array
          message.append_int FilterTypes[:values]
          message.append_int self.values.length
          append_array message, self.values
        end
        message.append_int self.exclude? ? 1 : 0
    
        message.to_s
      end
  
      private
  
      def append_integer_range(message, range)
        message.append_ints self.values.first, self.values.last
      end
  
      # Using to_f is a hack from the PHP client - to workaround 32bit signed
      # ints on x32 platforms
      def append_array(message, array)
        message.append_ints *array.collect { |val|
          case val
          when TrueClass
            1.0
          when FalseClass
            0.0
          else
            val.to_f
          end
        }
      end
    end
  end
end
