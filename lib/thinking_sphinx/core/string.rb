module ThinkingSphinx
  module Core
    module String
      
      def to_crc32
        result = 0xFFFFFFFF
        self.each_byte do |byte|
          result ^= byte
          8.times do
            result = (result >> 1) ^ (0xEDB88320 * (result & 1))
          end
        end
        result ^ 0xFFFFFFFF
      end
      
    end
  end
end

class String
  include ThinkingSphinx::Core::String
end