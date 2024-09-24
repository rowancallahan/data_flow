import YAML

export rule, create_rule, create_rule_instance, parse_yaml_rule, @rule_str
export backwards_solve_rule

#rule object for a general rule that carries information
#specifically from parsed rule yaml strings
struct rule
           input::Union{String, Vector{String}}
           output::String
  	       name::String
           command::String
end

#instance struct for an instance of a rule
struct rule_instance
           input::String
           output::String
  	       wildcard::String
  	       name::String
           command::String
end

#function to create rules
function create_rule(input, output, name, command)
        rule_out = rule(input, output, name, command)
	return rule_out
end


#function for parsing and creating rule instances
function create_rule_instance(rule_in, wildcard)
	input = replace(rule_in.input, "{sample}" => wildcard)
	output = replace(rule_in.output, "{sample}" => wildcard)
	name = rule_in.name
	command =  replace(rule_in.command,
		"{input}" => input,
		"{output}" => output,
		"{sample}" => wildcard  )
	
	return rule_instance(input, output, wildcard, name, command)
    
end

#function for basic parsing of a yaml string to create a rule
function parse_yaml_rule(yaml_string)
    option_dict = YAML.load(yaml_string)
	
    rule_out = rule(option_dict["input"],
		option_dict["output"],
		option_dict["name"],
		option_dict["command"])
	
	return rule_out
end

#macro to create special syntax for inline yaml strings that are parsed into rules
macro rule_str(rule_string)
	rule_out = parse_yaml_rule(rule_string)
	return rule_out
end


#rule for backwards solving to give you commands that you want to run
#given a list of wildcards a rule list and a head rule (optional)
#go through and create the backwards solved rules that will need
#to be run in order for you to be able to create all of the files that you care about
function backwards_solve_rule(rule_list, wildcard_list; head_rule=nothing, dryrun=true)
    #find the head rule and remove it from the list so that we can get all of the
  	#options for making stuff that we have
    if isnothing(head_rule)
        for rule in rule_list
            if rule.name=="all"
        		  	head_rule = rule
        		end
        end
       	rule_list = filter!(x->x!=head_rule, rule_list)
    end

	instance_options =Dict()
	for (wildcard_name, rule_name) in collect(Iterators.product(wildcard_list, rule_list) )
		rule_instance = create_rule_instance(rule_name, wildcard_name)
		if !(rule_name.output == "")
		    instance_options[rule_instance.output] = rule_instance
		end
	end
  
	#add the head rule that we will be working backwards from to make all the files
	#we will go through and see what files exist
	files_to_make = [head_rule.input...]
	rules_to_run = []
	starting_files = []

  #breadth first search to go through and find all the rules, or depth first
  #breadth first corresponds to rule order right. Depth first corresponds 
  #to finishing one sample in a row
  #at the right time	
	while length(files_to_make) >= 1
		file = pop!(files_to_make)
		if isfile(file)
			push!(starting_files, file)
		elseif haskey(instance_options, file)
			push!(files_to_make, instance_options[file].input)
			push!(rules_to_run, instance_options[file])
		else
			error("no input file found for file: $file")
		end
	end


  #check if things are a dry run if this is the case run what we want
  if dryrun	
	  println("these are the files to make $files_to_make")
    println("we are starting with these files $starting_files")
  	println("we will be running these rules $rules_to_run")
    for i in reverse(1:length(rules_to_run))
     	 println(rules_to_run[i].command)
    end
  #otherwise just return the order and the list that we want
  else
    println("no real solving yet for ordering in parallel, to implement!")
    return([rules_to_run, starting_files, files_to_make])
  end 


end


