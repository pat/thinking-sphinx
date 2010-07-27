Riddle::Client::Versions[:search]  = 0x117
Riddle::Client::Versions[:excerpt] = 0x102

class Riddle::Client
  private
  
  # Generation of the message to send to Sphinx for an excerpts request.
  def excerpts_message(options)
    message = Message.new
    
    message.append [0, excerpt_flags(options)].pack('N2') # 0 = mode
    message.append_string options[:index]
    message.append_string options[:words]
    
    # options
    message.append_string options[:before_match]
    message.append_string options[:after_match]
    message.append_string options[:chunk_separator]
    message.append_ints options[:limit], options[:around]
    message.append_ints options[:limit_passages], options[:limit_words]
    message.append_ints options[:start_passage_id]
    message.append_string options[:html_strip_mode]
    
    message.append_array options[:docs]
    
    message.to_s
  end
end