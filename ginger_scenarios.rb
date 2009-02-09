require 'ginger'

Ginger.configure do |config|
  config.aliases["active_record"] = "activerecord"
  config.aliases["active_support"] = "activesupport"
  
  ar_1_2_6 = Ginger::Scenario.new
  ar_1_2_6[/^active_?support$/] = "1.4.4"
  ar_1_2_6[/^active_?record$/] = "1.15.6"
  
  ar_2_0_4 = Ginger::Scenario.new
  ar_2_0_4[/^active_?support$/] = "2.0.4"
  ar_2_0_4[/^active_?record$/] = "2.0.4"
  
  ar_2_1_2 = Ginger::Scenario.new
  ar_2_1_2[/^active_?support$/] = "2.1.2"
  ar_2_1_2[/^active_?record$/] = "2.1.2"
  
  ar_2_2_0 = Ginger::Scenario.new
  ar_2_2_0[/^active_?support$/] = "2.2.0"
  ar_2_2_0[/^active_?record$/] = "2.2.0"
  
  ar_2_3_0 = Ginger::Scenario.new
  ar_2_3_0[/^active_?support$/] = "2.3.0"
  ar_2_3_0[/^active_?record$/] = "2.3.0"
  
  config.scenarios << ar_1_2_6 << ar_2_0_4 << ar_2_1_2 << ar_2_2_0 << ar_2_3_0
end