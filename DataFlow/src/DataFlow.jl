module DataFlow

import YAML
export glob_wildcards, expand

include("rule_operations.jl")

"""
 glob_wildcards(regex_in)

Get the wildcards for a list of strings that match a capture pattern.
Get all of the patterns that are captured with the regular expression within  a filepath.
Currently only works for the current filepath.
# Examples

```julia-repl

julia> matches  =  glob_wildcards("./(.*)_all_same_text.fastq")

#a list of string matches will be returned
```
"""
function glob_wildcards(regex_in)
		files = readdir()
		m = match.(regex_in, files)
		filter!(!isnothing, m)
		capture_list = map(x->x.captures[1], m)
		return(capture_list)
end



"""
 expand(string_in, expansion_list)
Expand the list of strings that have wildcards with the terms from your list
Currently this only works with strings that are formatted using "sample"
Will be changed to use macros later for processing.

# Examples

```julia-repl

julia> expanded_file_list =  expand("./{samples}_all_same_text.fastq", list_from_glob_wildcards)

#a list of strings  where {samples} is replaced with each of the instances of strings from the list already created with glob wildcards
```
"""
function expand(string_in, expansion_list)
	string_list = []
    for term in expansion_list
		push!(string_list, replace(string_in, "{sample}" => term))
	end
	return(String.(string_list))
end


		

end # module DataFlow
