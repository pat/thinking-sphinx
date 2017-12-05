# frozen_string_literal: true

class ThinkingSphinx::Middlewares::Inquirer <
  ThinkingSphinx::Middlewares::Middleware

  def call(contexts)
    @contexts = contexts
    @batch    = nil

    ThinkingSphinx::Logger.log :query, combined_queries do
      batch.results
    end

    index = 0
    contexts.each do |context|
      Inner.new(context).call batch.results[index], batch.results[index + 1]

      index += 2
    end

    app.call contexts
  end

  private

  def batch
    @batch ||= begin
      batch = ThinkingSphinx::Search::BatchInquirer.new

      @contexts.each do |context|
        batch.append_query context[:sphinxql].to_sql
        batch.append_query Riddle::Query.meta
      end

      batch
    end
  end

  def combined_queries
    @contexts.collect { |context| context[:sphinxql].to_sql }.join('; ')
  end

  class Inner
    def initialize(context)
      @context = context
    end

    def call(raw_results, meta_results)
      context[:results] = raw_results.to_a
      context[:raw]     = context[:results].dup
      context[:meta]    = meta_results.inject({}) { |hash, row|
        hash[row['Variable_name']] = row['Value']
        hash
      }

      total = context[:meta]['total_found']
      ThinkingSphinx::Logger.log :message, "Found #{total} result#{'s' unless total == 1}"
    end

    private

    attr_reader :context
  end
end
