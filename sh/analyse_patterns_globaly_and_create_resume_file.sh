#!/bin/sh
#
#       analyse_patterns_globaly_and_create_resume_file.sh
#       his script is a part of the COSP Workflow https://github.com/SmartBioInf/COSP/
#
#       Copyright 2021 INRAE / Sylvain Marthey <sylvain.marthey@inrae.fr>
#
#       This program is free software; you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation; either version 3 of the License, or
#       (at your option) any later version.
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#
#       You should have received a copy of the GNU General Public License
#       along with this program; if not, see <http://www.gnu.org/licenses/>.


function usage()
{
    echo "This script converts an EMBOSS fasta sequences header to tsv file contaning informations"
    echo ""
    echo "./convert_genome_header_to_annotation_table.sh"
    echo -e "\t-h --help"
    echo -e "\t--input_file            Genome fasta file from NCBI. [mandatory]"
    echo -e "\t--pattern_file          File containing patterns description. [mandatory]"
    echo -e "\t--global_pattern        Global pattern to find. String composed by a succession of one letter patterns codes. [mandatory]"
    echo -e "\t--patterns_to_Report    Patterns to retport. String composed by a succession of one letter patterns codes    . [mandatory]"
    echo -e "\t--genome_tab_file       Path of file containing genome informations (generated in previous step). [mandatory]"
    echo -e "\t--genome                Genoome Name. [mandatory]"
    echo ""
}

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        --input_file)
            INPUT=$VALUE
            ;;
        --pattern_file)
            pattern_file=$VALUE
            ;;
        --global_pattern)
            GlobalPattern=$VALUE
            ;;
        --patterns_to_Report)
            patternsToReport=$VALUE
            ;;
        --genome_tab_file)
            genomeTabFile=$VALUE
            ;;
        --genome)
            genome=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

if [ ! -f "$INPUT" ] 
then
    echo "Error: input_file parameter $INPUT does not exists."
    usage
    exit 1
fi

if [ ! -f "$pattern_file" ] 
then
    echo "Error: pattern_file parameter $pattern_file does not exists."
    usage
    exit 1
fi

if [ ! -f "$genomeTabFile" ] 
then
    echo "Error: genome_tab_file parameter $genomeTabFile does not exists."
    usage
    exit 1
fi

if [ -z "$GlobalPattern" ] 
then
    echo "Error: global_pattern parameter $GlobalPattern missing."
    usage
    exit 1
fi

if [ -z "$patternsToReport" ] 
then
    echo "Error: patterns_to_Report parameter $patternsToReport missing."
    usage
    exit 1
fi

if [ -z "$genome" ] 
then
    echo "Error: genome parameter $genome missing."
    usage
    exit 1
fi


########################
##### MAIN #############
########################

# sort file based query name and 
grep -v Pattern_name $INPUT \
| sort -t$'\t' +3 -4 +5n -6 \
| awk -F '\t' -v pattern_file=$pattern_file -v gPattern=$GlobalPattern \
              -v patternsToReport=$patternsToReport -v genomeTabFile=$genomeTabFile \
			  -v genome=$genome 'BEGIN{
    OFS="\t";
	j=1;
	curSeq = "";
	curGlobalPattern = "";
	report=0;
	success=0;
	gPatternPosition=1;
	nbPatterns=0;
	# read genome conf file and store patterns names in an array
	while(( getline line<pattern_file) > 0 ) {
		split(line,ln,"\t");
		if(j==1){
			if(ln[1]!="Name"){
				print "ERROR: File " patternsF " doesn t contain the mandatory Name column";
				exit 1;
			}
		}else{
			pattern[j-1]=ln[1];
			oneLetterCode[ln[3]]=ln[1];
		}
		j++;
	}
	# split global pattern and put in a table
	split(gPattern,gPatArray,"");
	for (k = 1 ; k <= length(gPattern); k++ ){
		if(!patterns[gPatArray[k]]){
			patterns[gPatArray[k]]="";
			nbPatterns++;
		}
	}
	# read genome tabulate file and store informations
	while(( getline line<genomeTabFile) > 0 ) {
		split(line,ln,"\t");
		annots[ln[1]]=ln[2];
		sequences[ln[1]]=ln[3];
	}
	# print header line
	header="genome\tprot_id\tannot\tglobal_pattern_" gPattern "\tobserved_pattern"
	for (k in patterns){
			 header = header "\t" oneLetterCode[k] ;
	}
	header = header "\tsequence";
	print header;
}{
    # if we are in a new sequence
	if($4 != curSeq){
		# test if the global pattern has been found
		if(gPatternPosition == (length(gPattern)+1)){
			success=1;
		}
		if(report>0){
			line= genome "\t" curSeq "\t" annots[curSeq] ;
			# add Success value
			if(success==1){
				line= line "\tYes";  
			}else{
				line= line "\t-";
			}
			# add curGlobalPattern
			line= line "\t" curGlobalPattern;
			# add patterns
			for (k in patterns){
				 sub(",","",patterns[k]);
				 line=line "\t" patterns[k];
			}
			# add sequence
			line=line "\t" sequences[curSeq];
			print line;
		}
		# reinitialize vars
		report=0;
		success=0;
		gPatternPosition=1;
		curGlobalPattern = "";
		for(k in patterns){
			patterns[k]="";
		}
	}
	curSeq = $4;
	# test if pattern allow to report
	curPattern = $10;
	if(patternsToReport ~ curPattern){
		report=1;
	}
	
	# test if pattern is compatible with global pattern shape
	if(curPattern == gPatArray[gPatternPosition]){
		gPatternPosition++;
	}
	# add pattern location to the list of pattern
	patterns[curPattern]=patterns[curPattern] ", " $9 ":" $6 "-" $7;
	# add pattern to current global pattern
	curGlobalPattern = curGlobalPattern curPattern;
	
}END{
	# test if the global pattern has been found
	if(gPatternPosition == (length(gPattern)+1)){
		success=1;
	}
	if(report>0){
		line= genome "\t" curSeq "\t" annots[curSeq] ;
		# add Success value
		if(success==1){
			line= line "\tYes";  
		}else{
			line= line "\t-";
		}
		# add curGlobalPattern
		line= line "\t" curGlobalPattern;
		# add patterns
		for (k in patterns){
			 sub(",","",patterns[k]);
			 line=line "\t" patterns[k];
		}
		# add sequence
		line=line "\t" sequences[curSeq];
		print line;
	}
}' 
