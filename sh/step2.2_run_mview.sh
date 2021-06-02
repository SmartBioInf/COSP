#!/bin/bash

source ~/.bashrc;

# load project configuration
source ../conf/config.txt

# remove previous html files
echo "remove previous MView html files";
rm -rf ${html_folder}/*-*_*.html;

echo "run MView on each cluatlo file";
# for all clustal files
for file in ${results_clustal}/*; do file_in=$(basename $file); file_out="${file_in%.*}" ; 
  $mview_bin -in clustal -html head -consensus on \
  -conservation on -sort pid -css on -coloring mismatch -colormap gray5 \
  -find 'F.G...H...W[PD]:[AG]G.W....[FY]P[GM]...D:G.G..[GA]' $file \
  > ${html_folder}/${file_out}.html 
done;
