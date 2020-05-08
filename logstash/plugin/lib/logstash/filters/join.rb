# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# This  filter will split event by array field, and later join back
class LogStash::Filters::Join < LogStash::Filters::Base

  FAILURE_TAG = '_foreach_failure'.freeze

  #
  # filter {
  #   foreach {
  #     task_id => "%{task_id}"
  #     field => "field_name"
  #   }
  # }
  #
  # ... Process records
  #
  # filter {
  #   join {
  #     join_fields => ["field_name"] List of fields to join together
  #     timeout => 60
  #   }
  # }
  #
  config_name "join"

  config :join_fields, :validate => :array

  config :timeout, :validate => :number, :default => 60

  public
  def register
    @tasks = {}
    @mutex = Mutex.new
  end # def register

  public
  def filter(event)

    task_id = event.get("[@metadata][task_id]")
    @logger.trace("task_id #{task_id}")
    if task_id.nil?
      filter_matched(event)
      return [event]
    end

    total = event.get("[@metadata][total_tasks]")
    if total.nil?
      @logger.error("Missing total #{task_id}")
      filter_matched(event)
      return [event]
    end

    if total == 0
      @logger.info("Event for id #{task_id} has no elements")
      filter_matched(event)
      return [event]
    end

    #Does this event match the expected schema?
    @join_fields.each do |field|
        if event.get(field).nil?
          @logger.error("Missing Join Field ", field)
          filter_matched(event)
          return [event]
        end
    end

    if !@tasks.key?(task_id)
      # first event becomes the schema for the aggregated event
        joined_event = event.clone

        #Is there a better way to convert to an array?
        @join_fields.each do |field|
            joined_event.set(field, [])
        end

        @tasks[task_id] = {:event => joined_event, :count => 0, :total => total}
    end

    task = @tasks[task_id]
    @logger.trace("found task #{task[:count]} of #{task[:total]} for id #{task_id}")
    @join_fields.each do |field|
        field_aggregate = task[:event].get(field)
        field_aggregate << event.get(field)
        task[:event].set(field, field_aggregate)
    end
    task[:count] += 1

    event.cancel

    #TODO: It's possible that not all events will make it, implement a time out.
    if task[:count] >= task[:total]
        @logger.debug("Yielding aggregate for #{task_id}")
        @tasks.delete(task_id)
        return task[:event]
    end
  end # def filter
end # class LogStash::Filters::Foreach
