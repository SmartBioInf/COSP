#!/bin/bash

source ~/.bashrc;

# load project configuration
source ../conf/config.txt

# read genome file 
awk -F '\t' -v gloc=$Genomes_folder -v shF=$sh_folder "BEGIN{
		i=1;
}{
	# retrive header information in first line
	if(i==1){
		# test presence of mandatory File column
		if(\$3!=\"File\"){
			print \"ERROR: genome configuration file doesn't contain the mandatory File column\";
			exit 1;
		}
	}else{
		cmd = shF \"/convert_fasta_to_tabulate.sh --input_file=\" gloc \"/\" \$3 ;
		# print cmd;
		system(cmd);	
	}
	i++;
}" $Conf_genomes
