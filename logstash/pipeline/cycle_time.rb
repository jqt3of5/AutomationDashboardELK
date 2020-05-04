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
  transitions = event.get("[issues][transitions]")

  cycleTime = 0

  transitions.each do |transition|
    if transition["statusCategory"] == "InProgress"
      cycleTime += transition["timeInStatus"]
    end
  end

  event.set("[issues][CycleTime]", cycleTime)
  [event]
end

def isStatusInProgress(status)

end