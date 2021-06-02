#!/bin/bash

source ~/.bashrc;

# load project configuration
source ../conf/config.txt

# create genome folder (if needed)
mkdir $fuzzPro_folder

# read pattern file 
if [ ! -f ../conf/patterns.txt ]; then
    echo "ERROR: File patterns.txt not found in conf/ folder!"
    exit 1 
else 
    # echo "launch awk command";
	awk -F '\t' -v gloc=$Genomes_folder -v fuzloc=$fuzzPro_folder -v fuzz=$fuzzPro_bin -v user=$userMail -v useClust=$use_cluster -v sgeQueue=$sgeQueue "BEGIN{
		i=1;
		j=1;
		# read genome conf file and store genomes names in an array
		while(( getline line<\"../conf/genomes.txt\") > 0 ) {
			split(line,ln,\"\t\");
			if(j==1){
				if(ln[1]!=\"Name\"){
					print \"ERROR: File genome.txt doesn't contain the mandatory Name column\";
					exit 1;
				}
			}else{
				genomes[j-1]=ln[1];
				fasta[j-1]=ln[3];
				# print \"Genome: \" ln[1] \" fasta_file: \" ln[3] ;
			}
			j++;
		}
	}{
		# retrive header information in first line
		if(i==1){
			# print \"# read pattern.txt file\" ;
			# test presence of mandatory Pattern column
			if(\$2!=\"Pattern\"){
				print \"ERROR: File pattern.txt doesn't contain the mandatory Pattern column\";
				exit 1;
			}
		}else{
			# create commands to run fuzzpro jobs
			for (j in genomes){
				# if we run on sge cluster 	
				if(toupper(useClust) == \"YES\"){
					cmd4= \"qsub -cwd -V -S /bin/bash -N fuzzpro_\" \$1 \"_\" j \" -m ea -b y -q \" sgeQueue \" -M \" user ;
					cmd4= cmd4 \" -o \" fuzloc \"/\" \$1 \"_vs_\" genomes[j] \".out\";
					cmd4= cmd4 \" -e \" fuzloc \"/\" \$1 \"_vs_\" genomes[j] \".err\";
					cmd4= cmd4 \" 'source ~/.bashrc;\";
					cmd4= cmd4 \" time \" fuzz \" -sequence \" gloc \"/\" fasta[j] \" -pattern \" \$2 \" -outfile \" fuzloc \"/\" genomes[j] \"_vs_\" \$1 \".fuzz.txt'\" ;
					# print cmd4;
					system(cmd4);
				}else{
					cmd4= \"source ~/.bashrc;\";
					cmd4= cmd4 \" time \" fuzz \" -sequence \" gloc \"/\" fasta[j] \" -pattern \" \$2 \" -outfile \" fuzloc \"/\" genomes[j] \"_vs_\" \$1 \".fuzz.txt\" ;
					# print cmd4;
					system(cmd4);
				}
			}

		}
		i++;
	}" $Conf_patterns
fi
