# Example Workflow for using this project


(@v1.10) pkg> activate DataFlow/
  Activating project at `~/data_flow/DataFlow`

julia> using DataFlow
Precompiling DataFlow
  1 dependency successfully precompiled in 3 seconds. 5 already precompiled.

julia> fastq_start_rule = create_rule("sample_number{sample}.fastq", "in{sample}.txt", "process_start", "echo {input}>{output}")
rule("sample_number{sample}.fastq", "in{sample}.txt", "process_start", "echo {input}>{output}")

julia> process_rule = create_rule("in{sample}.txt", "out{sample}.txt", "process", "sh echo {input} > {output}")
rule("in{sample}.txt", "out{sample}.txt", "process", "sh echo {input} > {output}")

julia> wildcards = glob_wildcards(r"sample_number(.*).fastq")
5-element Vector{SubString{String}}:
 "1potato"
 "2potato"
 "3potato"
 "4potato"
 "5potato"

julia> total_sample_list = expand("out{sample}.txt", wildcards)
5-element Vector{String}:
 "out1potato.txt"
 "out2potato.txt"
 "out3potato.txt"
 "out4potato.txt"
 "out5potato.txt"

julia> final_rule = create_rule(total_sample_list, "", "all", "")
rule(["out1potato.txt", "out2potato.txt", "out3potato.txt", "out4potato.txt", "out5potato.txt"], "", "all", "")

julia> rule_list_wflow = [final_rule, process_rule, fastq_start_rule]
3-element Vector{rule}:
 rule(["out1potato.txt", "out2potato.txt", "out3potato.txt", "out4potato.txt", "out5potato.txt"], "", "all", "")
 rule("in{sample}.txt", "out{sample}.txt", "process", "sh echo {input} > {output}")
 rule("sample_number{sample}.fastq", "in{sample}.txt", "process_start", "echo {input}>{output}")

julia> backwards_solve_rule(rule_list_wflow, wildcards)
these are the files to make String[]
we are starting with these files Any["sample_number5potato.fastq", "sample_number4potato.fastq", "sample_number3potato.fastq", "sample_number2potato.fastq", "sample_number1potato.fastq"]
we will be running these rules Any[DataFlow.rule_instance("in5potato.txt", "out5potato.txt", "5potato", "process", "sh echo in5potato.txt > out5potato.txt"), DataFlow.rule_instance("sample_number5potato.fastq", "in5potato.txt", "5potato", "process_start", "echo sample_number5potato.fastq>in5potato.txt"), DataFlow.rule_instance("in4potato.txt", "out4potato.txt", "4potato", "process", "sh echo in4potato.txt > out4potato.txt"), DataFlow.rule_instance("sample_number4potato.fastq", "in4potato.txt", "4potato", "process_start", "echo sample_number4potato.fastq>in4potato.txt"), DataFlow.rule_instance("in3potato.txt", "out3potato.txt", "3potato", "process", "sh echo in3potato.txt > out3potato.txt"), DataFlow.rule_instance("sample_number3potato.fastq", "in3potato.txt", "3potato", "process_start", "echo sample_number3potato.fastq>in3potato.txt"), DataFlow.rule_instance("in2potato.txt", "out2potato.txt", "2potato", "process", "sh echo in2potato.txt > out2potato.txt"), DataFlow.rule_instance("sample_number2potato.fastq", "in2potato.txt", "2potato", "process_start", "echo sample_number2potato.fastq>in2potato.txt"), DataFlow.rule_instance("in1potato.txt", "out1potato.txt", "1potato", "process", "sh echo in1potato.txt > out1potato.txt"), DataFlow.rule_instance("sample_number1potato.fastq", "in1potato.txt", "1potato", "process_start", "echo sample_number1potato.fastq>in1potato.txt")]
echo sample_number1potato.fastq>in1potato.txt
sh echo in1potato.txt > out1potato.txt
echo sample_number2potato.fastq>in2potato.txt
sh echo in2potato.txt > out2potato.txt
echo sample_number3potato.fastq>in3potato.txt
sh echo in3potato.txt > out3potato.txt
echo sample_number4potato.fastq>in4potato.txt
sh echo in4potato.txt > out4potato.txt
echo sample_number5potato.fastq>in5potato.txt
sh echo in5potato.txt > out5potato.txt

