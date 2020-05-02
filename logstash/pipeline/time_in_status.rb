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

    histories = event.get("[issues][changelog][histories]")
    transitions = histories.flat_map { |history|
        history["items"].select { |item|
            item["field"] == "status"
        }.map { |item|
            hist = history.clone
            hist["previous_status"] = item["fromString"]
            hist["status"] = item["toString"]
            hist["previous_status_id"] = item["from"]
            hist["status_id"] = item["to"]
            hist.delete("items")
            #TODO: Use Status Object from GET /rest/2/status

            hist
        }
    }

    transitions.each { |transition|
        next_transition = transitions.select{ |trans|
            trans["previous_status_id"] == transition["status_id"] && trans["created"] > transition["created"]
        }.min{ |a, b| a["created"] <=> b["created"] }

        if !next_transition.nil?
            transition["nextTransition"] = next_transition["created"]

            next_date = DateTime.parse(next_transition["created"])
            current_date = DateTime.parse(transition["created"])

            transition["timeInStatus"] = (next_date - current_date).to_f
        else
            transition["nextTransition"] = nil
        end
    }

    event.set("[issues][transitions]", transitions)

    return [event]
# return [] # return empty array to cancel event
end