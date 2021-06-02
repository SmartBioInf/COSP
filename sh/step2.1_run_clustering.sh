#!/bin/bash

source ~/.bashrc;

# load project configuration
source ../conf/config.txt

rm -rf $clustering_folder;
rm -rf $results_clustal;

# make clustering directory
echo "make clustering directory";
mkdir $clustering_folder;
temporary_folder="${clustering_folder}/temp"

mkdir $temporary_folder;
mkdir $results_clustal;


# merge genome resume files  
awk -F '\t' -v clustering_folder=$temporary_folder \
			-v fuzzPro_folder=$fuzzPro_folder 'BEGIN{
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
		if(i==2){
			cmd = "cat " fuzzPro_folder "/" $1 "_resume_fuzzpro.txt | grep -v observed_pattern > " clustering_folder "/proteines_for_clustering.tsv" ;
		}else{
			cmd = "cat " fuzzPro_folder "/" $1 "_resume_fuzzpro.txt | grep -v observed_pattern >> " clustering_folder "/proteines_for_clustering.tsv" ;
		}
		#print cmd;
		system(cmd);
	}
	i++;
}' $Conf_genomes

# create global fasta file 
awk -F '\t' '{
	# add genome name to proteine ID 
	split($1,species,"_");
	split(species[1],genre,"");
	print ">" genre[1] "." species[2] "_" $2 " " $3 ;
	print $9;
}' ${temporary_folder}/proteines_for_clustering.tsv > ${temporary_folder}/proteines_for_clustering.fasta

cp ${temporary_folder}/proteines_for_clustering.fasta ${clustering_folder}/proteines_for_clustering.fasta

#####################
# run clustering    #
#####################

# define files produced to be more conveniant whit the mmseq2 docuemntation and examples
DB="proteines_for_clustering"
DB_clu="proteines_for_clustering_clu"
DB_clu_rep="proteines_for_clustering_clu_rep"
DB_clu_msa="proteines_for_clustering_clu_msa"
DB_clu_seq="proteines_for_clustering_clu_seq"
DB_clu_seq_msa="proteines_for_clustering_clu_seq_msa"
tmp_folder="${temporary_folder}/tmp"

# activate conda env 
unset PYTHONPATH; 
conda activate ${condaEnvMMseq};

# move to clustring folder
cd ${temporary_folder}

# make hhsuite db with 
echo "make hhsuite db with"
mmseqs createdb proteines_for_clustering.fasta $DB

# make clustering with parameters defined in config.txt
echo "make clustering with parameters defined in config.txt"
echo "mmseqs cluster $DB $DB_clu $tmp_folder --min-seq-id ${min_seq_id}"
mmseqs ${mmseq2_clustering} $DB $DB_clu $tmp_folder --min-seq-id ${min_seq_id}

# create fasta file with sequences 
echo "create fasta file with sequences"
mmseqs createsubdb $DB_clu $DB $DB_clu_rep
mmseqs convert2fasta $DB_clu_rep ${DB_clu_rep}.fasta

# make tsv file
echo "make tsv file"
mmseqs createtsv $DB $DB $DB_clu ${DB_clu}.tsv

# make MSA file
echo "make MSA file"
mmseqs result2msa $DB $DB $DB_clu $DB_clu_msa

echo "load clustal condaenv"
conda activate ${condaEnvClustalo} --stack;

echo "run clustal"
mmseqs createseqfiledb $DB $DB_clu $DB_clu_seq
echo "mmseqs apply $DB_clu_seq $DB_clu_seq_msa -- clustalo -i - --threads=1"
mmseqs apply $DB_clu_seq $DB_clu_seq_msa -- clustalo -i - --threads=1 --outfmt clu
mmseqs apply $DB_clu_seq_msa ${DB_clu_seq_msa}.clustalo -- ${sh_folder}/create_clustal_file.sh $results_clustal

echo "rename files and clean directory"
mv $DB_clu_seq_msa ../
mv ${DB_clu}.tsv ../

rm -rf $temporary_folder


