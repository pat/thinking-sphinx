class Riddle::AutoVersion
  def self.configure
    controller = Riddle::Controller.new nil, ''
    version    = controller.sphinx_version
    
    case version
    when '0.9.8', '0.9.9'
      require "riddle/#{version}"
    when '1.10-beta', '1.10-id64-beta', '1.10-dev'
      require 'riddle/1.10'
    when /2.0.1/
      require 'riddle/2.0.1'
    else
      puts "found version: #{version}"
      exit
    end
  end
end
