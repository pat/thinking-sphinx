require 'ginger'

Ginger.configure do |config|
  config.aliases["active_record"] = "activerecord"
  config.aliases["active_support"] = "activesupport"
  
  ar_1_2 = Ginger::Scenario.new # 1.2.6
  ar_1_2[/^active_?support$/] = "1.4.4"
  ar_1_2[/^active_?record$/] = "1.15.6"
  
  ar_2_0 = Ginger::Scenario.new
  ar_2_0[/^active_?support$/] = "2.0.5"
  ar_2_0[/^active_?record$/] = "2.0.5"
  
  ar_2_1 = Ginger::Scenario.new
  ar_2_1[/^active_?support$/] = "2.1.2"
  ar_2_1[/^active_?record$/] = "2.1.2"
  
  ar_2_2 = Ginger::Scenario.new
  ar_2_2[/^active_?support$/] = "2.2.3"
  ar_2_2[/^active_?record$/] = "2.2.3"
  
  ar_2_3 = Ginger::Scenario.new
  ar_2_3[/^active_?support$/] = "2.3.4"
  ar_2_3[/^active_?record$/] = "2.3.4"
  
  config.scenarios << ar_1_2 << ar_2_0 << ar_2_1 << ar_2_2 << ar_2_3
end
