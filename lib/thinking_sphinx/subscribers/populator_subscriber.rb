class ThinkingSphinx::Subscribers::PopulatorSubscriber
  def self.attach_to(namespace)
    subscriber = new

    subscriber.public_methods(false).each do |event|
      next if event == :call

      ActiveSupport::Notifications.subscribe(
        "#{event}.#{namespace}", subscriber
      )
    end
  end

  def call(message, *args)
    send message.split('.').first,
      ActiveSupport::Notifications::Event.new(message, *args)
  end

  def start_populating(event)
    puts "Generating index files for #{event.payload[:index].name}"
  end

  def populated(event)
    print '.' * event.payload[:instances].length
  end

  def finish_populating(event)
    print "\n"
  end
end

ThinkingSphinx::Subscribers::PopulatorSubscriber.attach_to(
  'thinking_sphinx.real_time'
)
