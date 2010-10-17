module Rails
  def self.root
    File.join(Dir.pwd, 'tmp')
  end
  
  def self.env
    @@environment ||= 'development'
  end
  
  def self.env=(env)
    @@environment = env
  end
end
