class Riddle::Client::Filter
  #
  
  private
  
  def append_integer_range(message, range)
    message.append_64bit_ints self.values.first, self.values.last
  end
  
  def append_array(message, array)
    message.append_64bit_ints *array.collect { |val|
      case val
      when TrueClass
        1
      when FalseClass
        0
      else
        val
      end
    }
  end
end
