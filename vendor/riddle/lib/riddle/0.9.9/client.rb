Riddle::Client::Versions[:search] = 0x116
Riddle::Client::Versions[:update] = 0x102

class Riddle::Client
  private
  
  def initialise_connection
    socket = initialise_socket

    # Send version
    socket.send [1].pack('N'), 0
    
    # Checking version
    version = socket.recv(4).unpack('N*').first
    if version < 1
      socket.close
      raise VersionError, "Can only connect to searchd version 1.0 or better, not version #{version}"
    end
    
    socket
  end
  
  def update_message(index, attributes, values_by_doc)
    message = Message.new
    
    message.append_string index
    message.append_int attributes.length
    attributes.each_with_index do |attribute, index|
      message.append_string attribute
      message.append_boolean values_by_doc.values.first[index].is_a?(Array)
    end
    
    message.append_int values_by_doc.length
    values_by_doc.each do |key,values|
      message.append_64bit_int key # document ID
      values.each do |value|
        case value
        when Array
          message.append_int value.length
          message.append_ints *value
        else
          message.append_int value
        end
      end
    end
    
    message.to_s
  end
end
