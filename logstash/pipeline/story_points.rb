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
  storyPoints = event.get("[issues][fields][customfield_10052]")
  
  sizes = {"XS" => 1, "S" => 3, "M" => 5, "L" => 10, "XL" => 15}
  components = event.get("[issues][fields][components]").select do |c|
    sizes.include? c["name"]
  end

  if storyPoints.nil?
    unless components.empty?
      size = components.first["name"]

      event.set("[issues][fields][customfield_10052]", sizes[size])
    end
  end

end