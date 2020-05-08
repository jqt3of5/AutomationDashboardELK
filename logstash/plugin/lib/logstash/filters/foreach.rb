# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# This  filter will split event by array field, and later join back
class LogStash::Filters::Foreach < LogStash::Filters::Base

  FAILURE_TAG = '_foreach_failure'.freeze

  #
  # filter {
  #   foreach {
  #     task_id => "%{task_id}"
  #     field => "field_name"
  #     TODO:
  #     orderBy => "field_name"
  #     ascending = > true
  #   }
  # }
  #
  # ... Process records
  #
  # filter {
  #   join {
  #     join_fields => "field_name"
  #   }
  # }
  #
  config_name "foreach"

  config :task_id, :validate => :string, :required => true
  config :field, :validate => :string, :required => true

  public
  def register
    @mutex = Mutex.new
    # validate task_id option
    if !@task_id.match(/%\{.+\}/)
      raise LogStash::ConfigurationError, "Foreach plugin: task_id pattern '#{@task_id}' must contain a dynamic expression like '%{field}'"
    end

    @logger.error("Start: ", @task_id)
    if !@field.is_a?(String)
        raise LogStash::ConfigurationError, "Foreach plugin: For task_id pattern '#{@task_id}': field should be a field name, but it is of type = #{@field.class}"
    end
  end # def register

  public
  def filter(event)

    task_id = event.sprintf(@task_id)

    @logger.debug("task_id #{task_id}")

    if task_id.nil? || task_id == @task_id
      @logger.error("bad task_id #{task_id}")
      event.tag(FAILURE_TAG)
      filter_matched(event)
      yield event
      return
    end

    array_field_values = event.get(@field)

    event_split = event.clone
    event_split.set("[@metadata][task_id]", task_id)

    if !array_field_values.is_a?(Array)
        @logger.trace("Foreach plugin: if !array_field.is_a?(Array)");
        @logger.error("Foreach plugin: Field should be of Array type. field:#{@field} is of type = #{array_field_values.class}. Passing through")
        event_split.tag(FAILURE_TAG)
        event_split.set("[@metadata][task_id]", task_id)
        event_split.set("[@metadata][total_tasks]", 1)
        event_split.set("[@metadata][current_task]", 0)

        filter_matched(event_split)
        yield event_split
    else
      event_split.set("[@metadata][total_tasks]", array_field_values.length)

      if array_field_values.empty?
         @logger.debug("array_field_values is empty")
         event_split.set("[@metadata][current_task]", 0)

         filter_matched(event_split)
         yield event_split
      else
        array_field_values.each_with_index do |value, index|

          event_split = event.clone
          event_split.set(@field, value)
          @logger.trace("yielding task iteration #{task_id}")
          event_split.set("[@metadata][current_task]", index)

          filter_matched(event_split)
          yield event_split
        end
      end
    end

    event.cancel
  end # def filter

end # class LogStash::Filters::Foreach
