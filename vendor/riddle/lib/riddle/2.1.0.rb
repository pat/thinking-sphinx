require 'riddle/0.9.9'
require 'riddle/1.10'
require 'riddle/2.0.1'

Riddle.loaded_version = '2.1.0'

Riddle::Client::Versions[:search]  = 0x119
Riddle::Client::Versions[:excerpt] = 0x104

Riddle::Client::RankModes[:expr]  = 8
Riddle::Client::RankModes[:total] = 9

Riddle::Client::AttributeTypes[:multi]    = 0x40000001
Riddle::Client::AttributeTypes[:multi_64] = 0x40000002

Riddle::Client::AttributeHandlers[Riddle::Client::AttributeTypes[:multi_64]] = :next_64bit_int_array
