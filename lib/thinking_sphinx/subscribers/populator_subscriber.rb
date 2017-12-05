# frozen_string_literal: true

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

  def error(event)
    error    = event.payload[:error].inner_exception
    instance = event.payload[:error].instance

    puts <<-MESSAGE

Error transcribing #{instance.class} #{instance.id}:
#{error.message}
    MESSAGE
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

  private

  delegate :output, :to => ThinkingSphinx
  delegate :puts, :print, :to => :output
end

ThinkingSphinx::Subscribers::PopulatorSubscriber.attach_to(
  'thinking_sphinx.real_time'
)
