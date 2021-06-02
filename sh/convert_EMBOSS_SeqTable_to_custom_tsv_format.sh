#!/bin/sh
#
#       convert_EMBOSS_SeqTable_to_custom_tsv_format.sh
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
    echo "This script converts an EMBOSS SeqTable file provided by fuzzPro to a custom tsv format"
    echo ""
    echo "./addss_for_all_msa_in_input_file.sh"
    echo -e "\t-h --help"
    echo -e "\t--input_file            Pattern alignment file in EMBOSS SeqTable format (provided by EMBO FuzzPro). [mandatory]"
    echo -e "\t--pattern_name          Pattern identifier for reporting in out file [mandatory]"
    echo -e "\t--genome_name           Genome identifier for reporting in out file [mandatory]"
    echo -e "\t--header                print header or not [yes|no] defaut yes"
    echo -e "\t--code                  one letter code corresponding to searched pattern"
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
        --pattern_name)
            pattern_name=$VALUE
            ;;
        --genome_name)
            genome_name=$VALUE
            ;;
        --header)
            header=$VALUE
            ;;
        --code)
            code=$VALUE
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

if [ -z "$pattern_name" ]
then
    echo "Error: No pattern_name provided"
	usage
    exit 1
fi

if [ -z "$genome_name" ]
then
    echo "Error: No genome_name provided"
	usage
    exit 1
fi

if [ -z "$header" ]
then
    header="yes";
fi

if [ -z "$code" ]
then
    code="no";
fi
########################
##### MAIN #############
########################


cat $INPUT \
| awk '{
   if($0 ~ /Sequence:/ || $0 ~ /pattern:/){
      print $0;
   }
}' \
| sed -E 's/ +/\t/g' \
| sed -E s'/^\t//' \
| awk -F '\t' -v pattern_name=$pattern_name -v genome_name=$genome_name -v header=$header -v code=$code 'BEGIN{
	OFS="\t";
	if(header=="yes"){
		headerLine="Genome\tPattern_name\tPattern\tSequence\tSequence_size\tstart\tstop\tmismatch\tobserved_seq";
	    if(length(code)==1){
			headerLine=headerLine "\tcode";
		}
		print headerLine;
	}
}
{
    if($2=="Sequence:"){
	    seq=$3;size=$7
    }else{
		# add code at the end of the line 
		if(length(code)==1){
			$5 = $5 "\t" code;
		}
	    print  genome_name "\t" pattern_name "\t" $3 "\t" seq "\t" size "\t" $1 "\t" $2 "\t" $4 "\t" $5 ;
    }
}' \
| sed -E 's/\tpattern:([^\t]+)\t([^\t]+)\t/\t\1\t\2\t/' 




