### A Pluto.jl notebook ###
# v0.19.37

using Markdown
using InteractiveUtils

# ╔═╡ 34ea0d3c-f3c9-4849-bc1a-3b724437ec12
using YAML

# ╔═╡ 77d320b8-0be2-4f9a-a429-027593be6588
struct rule
           input::Union{String, Vector{String}}
           output::String
	       name::String
           command::String
end

# ╔═╡ 8ac9f664-bd1a-4b2a-98fa-a17d1f831e24
struct rule_instance
           input::String
           output::String
	       wildcard::String
	       name::String
           command::String
end

# ╔═╡ c627871a-c7c7-469c-ab86-9036099b2c49
function create_rule(input, output, name, command)
        rule_out = rule(input, output, name, command)
	return rule_out
end

# ╔═╡ c69c90cc-48bc-403e-855a-26236beffe55
process_rule = create_rule("in{sample}.txt", "out{sample}.txt", "process", "sh echo {input} > {output}")

# ╔═╡ 5c39ccff-29dd-40bd-9e15-46ba6384da9f
fastq_start_rule = create_rule("sample_number{sample}.fastq", "in{sample}.txt", "process_start", "echo {input}>{output}")

# ╔═╡ bcaa7b7b-1a9d-4806-a13f-c9eb65622ac6
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

# ╔═╡ c5194ea9-cfb6-4dca-9d47-b7bb8ef43d7e

function glob_wildcards(regex_in)
		files = readdir()
		m = match.(regex_in, files)
		filter!(!isnothing, m)
		capture_list = map(x->x.captures[1], m)
		return(capture_list)
end
	
	#glob then just string replace could use automa
	#dag solver. topological sort, then start from teh bottom in terms of getting an order of things to run
	#glob finder for wildcards
	#start w glob finder to find outputs
	#then do dag solver


# ╔═╡ 4d12bb27-b034-485f-a17b-1f566f58ef6e
function expand(string_in, expansion_list)
	string_list = []
    for term in expansion_list
		push!(string_list, replace(string_in, "{sample}" => term))
	end
	return(String.(string_list))
end
		

# ╔═╡ 8272c67e-d0fa-470e-9531-4957fe819b56
begin
    wildcard_list = glob_wildcards(r"sample_number(.*).fastq")
    total_sample_list = expand("out{sample}.txt", wildcard_list)
    final_rule = create_rule(total_sample_list, "", "all", "")
end

# ╔═╡ 07238ac7-2072-48ef-81ba-13cea91c25e0
begin
	rule_list = [final_rule, process_rule, fastq_start_rule]
	head_rule = nothing
	for rule in rule_list
		if rule.name=="all"
			global head_rule = rule
		end
	end
	rule_list = filter!(x->x!=head_rule, rule_list)
    #find the head rule and remove it from the list so that we can get all of the
	#options for making stuff that we have

	#get ready all of the options for rules that we could run that could make the
	#files that we want as our target files that we care about
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
	println("these are the files to make $files_to_make")
	
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
	
    println("we are starting with these files $starting_files")
	println("we will be running these rules $rules_to_run")

	for i in reverse(1:length(rules_to_run))
		println(rules_to_run[i].command)
	end
		
	
end

# ╔═╡ d92df800-3c96-4add-a87c-df6589b311f4
rule_list

# ╔═╡ 091789d1-6fdc-44f7-a98a-df0804d98bed
function parse_yaml_rule(yaml_string)
    option_dict = YAML.load(yaml_string)
	
    rule_out = rule(option_dict["input"],
		option_dict["output"],
		option_dict["name"],
		option_dict["command"])
	
	return rule_out
end

# ╔═╡ fe86615d-abb9-4530-a0b9-037a1c8ca637
macro rule_str(rule_string)
	rule_out = parse_yaml_rule(rule_string)
	return rule_out
end

# ╔═╡ 95aa2a61-7c2d-4e49-a3fd-aec3d1add9e0
testrule = rule"""
name:
    testrule
input: 
    in{sample}.txt
output:
    out{sample}.txt
command:
    echo {input} >{output}
   
"""

# ╔═╡ 0c9fa892-d6b0-4394-8e9c-4c7e91f08a8a


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
YAML = "ddb6d928-2868-570f-bddf-ab3f9cf99eb6"

[compat]
YAML = "~0.4.12"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.0"
manifest_format = "2.0"
project_hash = "328c9a8b3468ed43564c44162d291584c17c2751"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "f389674c99bfcde17dc57454011aa44d5a260a40"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.6.0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "f9557a255370125b405568f9767d6d195822a175"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.17.0+0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.StringEncodings]]
deps = ["Libiconv_jll"]
git-tree-sha1 = "b765e46ba27ecf6b44faf70df40c57aa3a547dcb"
uuid = "69024149-9ee7-55f6-a4c4-859efe599b68"
version = "0.3.7"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.YAML]]
deps = ["Base64", "Dates", "Printf", "StringEncodings"]
git-tree-sha1 = "dea63ff72079443240fbd013ba006bcbc8a9ac00"
uuid = "ddb6d928-2868-570f-bddf-ab3f9cf99eb6"
version = "0.4.12"
"""

# ╔═╡ Cell order:
# ╠═77d320b8-0be2-4f9a-a429-027593be6588
# ╠═8ac9f664-bd1a-4b2a-98fa-a17d1f831e24
# ╠═c627871a-c7c7-469c-ab86-9036099b2c49
# ╠═c69c90cc-48bc-403e-855a-26236beffe55
# ╠═5c39ccff-29dd-40bd-9e15-46ba6384da9f
# ╠═bcaa7b7b-1a9d-4806-a13f-c9eb65622ac6
# ╠═c5194ea9-cfb6-4dca-9d47-b7bb8ef43d7e
# ╠═4d12bb27-b034-485f-a17b-1f566f58ef6e
# ╠═8272c67e-d0fa-470e-9531-4957fe819b56
# ╠═07238ac7-2072-48ef-81ba-13cea91c25e0
# ╠═d92df800-3c96-4add-a87c-df6589b311f4
# ╠═34ea0d3c-f3c9-4849-bc1a-3b724437ec12
# ╠═091789d1-6fdc-44f7-a98a-df0804d98bed
# ╠═fe86615d-abb9-4530-a0b9-037a1c8ca637
# ╠═95aa2a61-7c2d-4e49-a3fd-aec3d1add9e0
# ╠═0c9fa892-d6b0-4394-8e9c-4c7e91f08a8a
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
