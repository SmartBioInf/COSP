#!/bin/sh

echo "step1.1_run_FuzzPro_on_genomes.sh"
./step1.1_run_FuzzPro_on_genomes.sh

echo "step1.2_convert_FuzzPro_results_to_tsv.sh"
./step1.2_convert_FuzzPro_results_to_tsv.sh

echo "step1.3_convert_genomes_fasta_files_to_tsv.sh"
./step1.3_convert_genomes_fasta_files_to_tsv.sh

echo "step1.4_global_patterns_identification.sh"
./step1.4_global_patterns_identification.sh

echo "step2.1_run_clustering.sh"
./step2.1_run_clustering.sh

echo "step2.2_run_mview.sh"
./step2.2_run_mview.sh

echo "step3.1_add_clusters_to_global_results_file.sh"
./step3.1_add_clusters_to_global_results_file.sh
