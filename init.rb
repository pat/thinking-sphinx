# Dir[File.join(File.dirname(__FILE__), 'vendor/*/lib')].each do |path|
#   $LOAD_PATH.unshift path
# end

require File.join(File.dirname(__FILE__), "lib", "thinking_sphinx")

require 'thinking_sphinx'