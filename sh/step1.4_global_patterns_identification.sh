#!/bin/bash

source ~/.bashrc;

# load project configuration
source ../conf/config.txt

# read genome file 
awk -F '\t' -v gloc=$Genomes_folder -v shF=$sh_folder -v fuzloc=$fuzzPro_folder \
            -v conf_patterns=$Conf_patterns -v global_pattern=$GlobalPattern \
			-v patterns_to_report=$patternsToReport 'BEGIN{
		i=1;
}{
	# retrive header information in first line
	if(i==1){
		# test presence of mandatory File column
		if($3!="File"){
			print "ERROR: genome configuration file doesn t contain the mandatory File column";
			exit 1;
		}
	}else{
		# 
		cmd = shF "/analyse_patterns_globaly_and_create_resume_file.sh" ;
		cmd = cmd " --input_file=" fuzloc "/" $1 ".fuzz.tsv";
		cmd = cmd " --pattern_file=" conf_patterns;
		cmd = cmd " --global_pattern=" global_pattern;
		cmd = cmd " --patterns_to_Report=" patterns_to_report;
		cmd = cmd " --genome_tab_file=" gloc "/" $3 ".annot.tsv";
		cmd = cmd " --genome=" $1;
		cmd = cmd " > " fuzloc "/" $1 "_resume_fuzzpro.txt";
		print "process " $1 " results";
		# print cmd;
		system(cmd);
	}
	i++;
}' $Conf_genomes

