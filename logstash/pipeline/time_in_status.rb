require 'logstash/filters/split'

# the value of `params` is the value of the hash passed to `script_params`
# in the logstash configuration
def register(params)
	# @drop_percentage = params["percentage"]
end

# the filter method receives an event and must return a list of events.
# Dropping an event means not including it in the return array,
# while creating new ones only requires you to add a new instance of
# LogStash::Event to the returned array
def filter(event)

    split_events = LogStash::Filters::Split.new().filter(event)

    split_events.for_each { |e|
        history = e.get("[issues][changelog][histories]")

        if history.items.field == "status"
            next_events = split_events.filter{ |ev| ev.get("[issues][changelog][histories][items]").from == history.items.to && ev.get("[issues][changelog][histories]").created > history.created }
            if !next_events.empty?
                e.set("[issues][changelog][histories][nextTransition]",next_events.min { |a, b| a.created <=> b.created }.created )
            end
        end
    }

    return split_events
# return [] # return empty array to cancel event
end