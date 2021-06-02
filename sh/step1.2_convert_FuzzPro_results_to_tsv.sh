#!/bin/bash

source ~/.bashrc;

# load project configuration
source ../conf/config.txt

# read pattern file 
if [ ! -f ../conf/patterns.txt ]; then
    echo "ERROR: File patterns.txt not found in conf/ folder!"
    exit 1 
else 
    # echo "launch awk command";
	awk -F '\t' -v gloc=$Genomes_folder -v fuzloc=$fuzzPro_folder -v fuzz=$fuzzPro_bin -v patternsF=$Conf_patterns -v shF=$sh_folder "BEGIN{
		i=1;
		j=1;
		# read pattern conf file and store patterns names in an array
		while(( getline line<patternsF) > 0 ) {
			split(line,ln,\"\t\");
			if(j==1){
				if(ln[1]!=\"Name\"){
					print \"ERROR: File \" patternsF \" doesn't contain the mandatory Name column\";
					exit 1;
				}
			}else{
				pattern[j-1]=ln[1];
				oneLetterCode[j-1]=ln[3];
			}
			j++;
		}
	}{
		# retrive header information in first line
		if(i==1){
			# test presence of mandatory File column
			if(\$3!=\"File\"){
				print \"ERROR: genome configuration file doesn't contain the mandatory File column\";
				exit 1;
			}
		}else{
			# create commands to convert fuzzpro results to tabulate file
			for (j in pattern){
				cmd= shF \"/convert_EMBOSS_SeqTable_to_custom_tsv_format.sh\";
				cmd = cmd \" --input_file=\" fuzloc \"/\" \$1 \"_vs_\" pattern[j] \".fuzz.txt\" ;
				cmd = cmd \" --pattern_name=\" pattern[j] ;
				cmd = cmd \" --genome_name=\" \$1 ;
				cmd = cmd \" --code=\" oneLetterCode[j] ;
				# for the first time we create the file with header
				if(j==1){
					cmd = cmd \" --header=yes\";
					cmd = cmd \" > \" fuzloc \"/\" \$1 \".fuzz.tsv\";
				}else{
					cmd = cmd \" --header=no\";
					cmd = cmd \" >> \" fuzloc \"/\" \$1 \".fuzz.tsv\";
				}
				# print cmd;
				system(cmd);
			}

		}
		i++;
	}" $Conf_genomes
fi
