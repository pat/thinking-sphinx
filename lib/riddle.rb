require 'socket'
require 'riddle/client'
require 'riddle/client/filter'
require 'riddle/client/message'
require 'riddle/client/response'

module Riddle #:nodoc:
  class ConnectionError < StandardError #:nodoc:
  end
  
  module Version #:nodoc:
    Major = 0
    Minor = 9
    Tiny  = 8
    # Revision number for RubyForge's sake, taken from what Sphinx
    # outputs to the command line.
    Rev   = 1198
    
    String      = [Major, Minor, Tiny].join('.') + "rc1"
    GemVersion  = [Major, Minor, Tiny, Rev].join('.')
  end
end