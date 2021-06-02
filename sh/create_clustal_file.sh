#!/bin/sh
#
#       create_clustal_file.sh
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


awk -F ' ' -v output_folder=$1 'BEGIN{
	if(output_folder == "" || system("[ ! -d " output_folder " ]") == 0){
		print "ERROR: output_folder_path argument ($1) is not provided or is not a valid folder\n Usage : create_clustal_file.sh output_folder_path";
        exit 1;
	}
	prt = 0;
	i=0;
	ligne="";
	cluster_id="";
	file_out="";
}{
	if(i==0){
		ligne = ligne "\n" $0;
	}else if($1 == "" && prt == 0 ){
		ligne = ligne "\n" $0;
	}else if($1 != "" && prt == 0 ){
		cluster_id=$1;
		file_out= output_folder "/" cluster_id ".clustalo";
		ligne = ligne "\n" $0;
		prt = 1;
		print ligne > file_out ;
	}else {
		print $0 > file_out ;
	}
	i++;
}'



