module ThinkingSphinx
  module ActionController
    extend ActiveSupport::Concern

    protected

    attr_internal :query_runtime

    def cleanup_view_runtime
      log_subscriber = ThinkingSphinx::ActiveRecord::LogSubscriber
      query_runtime_pre_render = log_subscriber.reset_runtime
      runtime = super
      query_runtime_post_render = log_subscriber.reset_runtime
      self.query_runtime = query_runtime_pre_render + query_runtime_post_render
      runtime - query_runtime_post_render
    end

    def append_info_to_payload(payload)
      super
      payload[:query_runtime] = query_runtime
    end

    module ClassMethods
      def log_process_action(payload)
        messages, query_runtime = super, payload[:query_runtime]
        messages << ("Sphinx: %.3fms" % query_runtime.to_f) if query_runtime
        messages
      end
    end
  end
end
