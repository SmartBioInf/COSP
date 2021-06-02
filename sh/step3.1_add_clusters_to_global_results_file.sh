#!/bin/bash

source ~/.bashrc;

# load project configuration
source ../conf/config.txt

# make results directory if needed
if [ ! -d $results_folder ]
then
  echo "make results directory";
  mkdir $results_folder;
fi

# read genome file 
gawk -F '\t' -v fuzloc=$fuzzPro_folder \
            -v results_folder=$results_folder 'BEGIN{
		i=1;
		result_file=results_folder "/all_results_FuzzPro.fuzz.tsv";
		statistics_file=results_folder "/statistics_FuzzPro.fuzz.tsv";
}{
	# retrive header information in first line
	if(i==1){
		# test presence of mandatory File column
		if($3!="File"){
			print "ERROR: genome configuration file doesn t contain the mandatory File column";
			exit 1;
		}
	}else{
		# store genome name
		genomes[$1]=1;
		# merge all results files 
		if(i==2){
			cmd = "cp " fuzloc "/" $1 ".fuzz.tsv " result_file;
		}else{
		    cmd = "cat " fuzloc "/" $1 ".fuzz.tsv | grep -v Pattern_name >> " result_file;
		}
		system(cmd);
		# count nb sequences with compatible super pattern 
		cmd2 = "cut -f 4 " fuzloc "/" $1 "_resume_fuzzpro.txt | grep -c Yes"; 		
		cmd2|getline globalPatternOk[$1];
	}
	i++;
	close(result_file);
}END{
	# print "result file: " result_file ;
	# open general results file
	# skip first line
    getline line < (result_file);
	while(( getline line < (result_file) ) > 0 ) {
      split(line,ln,"\t");
      pattern[ln[1]][ln[2]][ln[4]]++;
	  patterns[ln[2]]++;
    }
	# count statistics 
	for (i in pattern){
		for (j in pattern[i]){
			ct=0;
			for (s in pattern[i][j]){
				ct++;
			}
			count[i][j]=ct;
		}
	}
	# print statistics
	print "print global statistics to file to " statistics_file; 
	txt = "Genome";
	for (i in patterns){
		txt = txt "\tNb_seqs_with_" i;
	}
	txt = txt "\tNb_seqs_with_global_pattern_RBVR" ;
	print txt > statistics_file;
	for (i in genomes){
		txt = i;
		for (j in patterns){
			txt = txt "\t" count[i][j];
		}
		# add number of sequences compatible with global pattern 
		txt = txt "\t" globalPatternOk[i];
		print txt > statistics_file;
	}
}' $Conf_genomes

# read cluster file
gawk -F '\t' -v fuzloc=$fuzzPro_folder -v results_folder=$results_folder -v clustering_folder=$clustering_folder \
    -v mmseq2_clustering=$mmseq2_clustering -v min_seq_id=$min_seq_id -v html_folder=$html_folder -v results_clustal=$results_clustal 'BEGIN{
	i=1;
	while(( getline line < (clustering_folder "/proteines_for_clustering_clu.tsv" ) ) > 0 ) {
		split(line,ln,"\t");
		# remove genome name from proteine id
		sub(/^[^_]+_/,"",ln[2]);
		# check if cluster has already been associated with a short ID
		if(clusterID[ln[1]] == ""){
			# create cluster id
			clust_id = "MMSEQ_"mmseq2_clustering "_ident-" min_seq_id "_" i ;
			clusterID[ln[1]] = clust_id;
			# store correspondance beween original cluster ID and new cluster ID
			correspondance[clust_id]=ln[1];
			i++;
		}
		cluster[ln[2]]=clusterID[ln[1]];
		nbSeqs[clusterID[ln[1]]]++;
	}
	i=1;
	head=0;
	result_file=results_folder "/all_genomes_fuzzpro_results.resume.tsv";
	print "merge fuzzpro resume files in file " result_file ;
}{
	# retrive header information in first line
	if(i==1){
		# test presence of mandatory File column
		if($3!="File"){
			print "ERROR: genome configuration file doesn t contain the mandatory File column";
			exit 1;
		}
	}else{
		# store genome name
		genomes[$1]=1;
		# test if a result file exist for this genome
		fuzzproFile = fuzloc "/" $1 "_resume_fuzzpro.txt";
		if (system("test -f " fuzzproFile) == 0){
			getline line < (fuzzproFile);
			# print header in result file
			if(head==0){
				line = line "\tcluster\tnb_seqs_in_cluster\trepresentative_cluster_seq";
				print line > result_file;
				head=1;
			}
			while(getline line < (fuzzproFile) > 0){
				split(line,ln,"\t");
				# retrive corresponding cluster if it exist
				clust = cluster[ln[2]];
				# si aucun cluster ou seul dans son custer
				if(!clust || nbSeqs[clust] == 1 ){
					clust = "-";
				}
				line = line "\t" clust "\t" nbSeqs[clust] "\t" correspondance[clust];
				print line > result_file;
			}
		}else{
			print "file " fuzzproFile " not found";
		}
	}
	i++;
}END{
	print "rename clustal files and Mview files";
	for (original_name in clusterID){
		if(nbSeqs[clusterID[original_name]] > 1){
			cmd1 = "mv " results_clustal "/" original_name ".clustalo " results_clustal "/" clusterID[original_name] ".clustalo";
			system(cmd1);
			cmd2 = "mv " html_folder "/" original_name ".html " html_folder "/" clusterID[original_name] ".html";
			system(cmd2);
		}
	}

}' $Conf_genomes



