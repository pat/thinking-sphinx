require 'zlib'

module ThinkingSphinx
  module Core
    module String
      def to_crc32
        Zlib.crc32 self
      end
    end
  end
end

class String
  include ThinkingSphinx::Core::String
end