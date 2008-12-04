require 'ginger'

Ginger.configure do |config|
  config.aliases["active_record"] = "activerecord"
  config.aliases["active_support"] = "activesupport"
  
  ar_1_2_6 = Ginger::Scenario.new
  ar_1_2_6[/^active_?support$/] = "1.4.4"
  ar_1_2_6[/^active_?record$/] = "1.15.6"
  
  ar_2_0_2 = Ginger::Scenario.new
  ar_2_0_2[/^active_?support$/] = "2.0.2"
  ar_2_0_2[/^active_?record$/] = "2.0.2"
  
  ar_2_1_1 = Ginger::Scenario.new
  ar_2_1_1[/^active_?support$/] = "2.1.1"
  ar_2_1_1[/^active_?record$/] = "2.1.1"
  
  ar_2_2_0 = Ginger::Scenario.new
  ar_2_2_0[/^active_?support$/] = "2.2.0"
  ar_2_2_0[/^active_?record$/] = "2.2.0"
  
  config.scenarios << ar_1_2_6 << ar_2_0_2 << ar_2_1_1 << ar_2_2_0
end