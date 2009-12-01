Dir[File.join(File.dirname(__FILE__), 'vendor/*/lib')].each do |path|
  $LOAD_PATH.unshift path
end

require 'thinking_sphinx'
