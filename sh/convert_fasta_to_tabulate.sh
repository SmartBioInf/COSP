#!/bin/sh
#
#       convert_fasta_to_tabulate.sh
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
    echo -e "\t--input_file            genome fasta file from NCBI. [mandatory]"
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

########################
##### MAIN #############
########################

echo -e "protein_id\tRaw annotation\tSequence" > ${INPUT}.annot.tsv ;

sed -E 's/\s/\t/' ${INPUT} \
| awk -F '\t' 'BEGIN{
	i=0;
}{
	if(i==0){
		header=$0;
	}else{
		if($0 ~ /^>/){
			print header "\t" seq ;
			header=$0;
			seq="";
		}else{
			seq = seq $0 ;
		}
	}
	i++;
}END{
	print header "\t" seq ;
}'  \
| sed -E 's/^>([^|]+\|)?//' >> ${INPUT}.annot.tsv

