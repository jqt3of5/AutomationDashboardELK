require 'logstash/filters/split'

# the value of `params` is the value of the hash passed to `script_params`
# in the logstash configuration
def register(params)
	# @drop_percentage = params["percentage"]
	@field = ""
end
def split(event, field)
    original_value = event.get(field)

    if original_value.is_a?(Array)
      splits = @target.nil? ? event.remove(field) : original_value
    elsif original_value.is_a?(String)
      # Using -1 for 'limit' on String#split makes ruby not drop trailing empty
      # splits.
      splits = original_value.split(@terminator, -1)
    else
      logger.warn("Only String and Array types are splittable. field:#{field} is of type = #{original_value.class}")
      #event.tag(PARSE_FAILURE_TAG)
      return
    end

    # Skip filtering if splitting this event resulted in only one thing found.
    return if splits.length == 1 && original_value.is_a?(String)

    # set event_target to @field if not configured
    event_target = field

    splits.each do |value|
      next if value.nil? || (value.is_a?(String) && value.empty?)

      event_split = event.clone
      event_split.set(event_target, value)
     # filter_matched(event_split)

      # Push this new event onto the stack at the LogStash::FilterWorker
      yield event_split
    end

    # Cancel this event, we'll use the newly generated ones above.
    event.cancel
end
# the filter method receives an event and must return a list of events.
# Dropping an event means not including it in the return array,
# while creating new ones only requires you to add a new instance of
# LogStash::Event to the returned array
def filter(event)

    events = []
    split(event,"[issues][changelog][histories]") { |event1|
        split(event1,"[issues][changelog][histories][items]") { |event2|
            events.push(event2)
        }
    }

    events.each { |e|
        history = e.get("[issues][changelog][histories]")

        if history["items"]["field"] == "status"
            next_events = events.filter{ |ev|
                ev.get("[issues][changelog][histories][items][from]") == history["items"]["to"] && ev.get("[issues][changelog][histories][created]") > history["created"]
             }
            if !next_events.empty?
                next_event = next_event.min { |a, b| a.get("[issues][changelog][histories][created]") <=> b.get("[issues][changelog][histories][created]") }
                e.set("[issues][changelog][histories][nextTransition]", next_event.get("[issues][changelog][histories][created]"))
            end
        end
    }

    return events
# return [] # return empty array to cancel event
end