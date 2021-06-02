//////////////////////////////////////////////
// function to display a tsv file in the html element #statistics_table
// HitLength : array containing range for Percentage of the Query sequence covered by the Hit
// data : data object. Array of objects. The keys of the first element of the table will be used as header
function tabulate(data) {
	
        //////////////////
	    // create link to file in download_statistics element
	    var link =  d3.select('#download_statistics')
                       .append("a")
                       .attr("href", "../results/statistics_FuzzPro.fuzz.tsv")
                       .text("Statistics file ")
                       .append("img")
                       .attr("src","img/file-earmark-spreadsheet.svg")
                       .attr("width","16px");
	
		//////////////////
		// create table in the #statistics_table element
		var table = d3.select('#statistics_table')
		              .append('table')
		              .attr("class", "table-striped table-hover table-bordered");
		// add thead to table
		var thead = table.append('thead');
		// add tbody to table
		var	tbody = table.append('tbody');
		
		// retrieve columns values
		var columns = Object.keys(data[0]);
		
		// append the header row
		thead.append('tr')
		  .selectAll('th')
		  .data(columns).enter()
		  .append('th')
		    .style("padding-left", "10px")
		    .style("padding-right", "10px")
		    .text(function (column) { return column; });

		// create a row for each object in the data
		var rows = tbody.selectAll('tr')
		  .data(data)
		  .enter()
		  .append('tr');

		// create a cell in each row for each column
		var cells = rows.selectAll('td')
		  .data(function (row) {
		    return columns.map(function (column) {
		      return {column: column, value: row[column]};
		    });
		  })
		  .enter()
		  .append('td')
		    .style("padding-left", "10px")
		    .text(function (d) { return d.value; });

	  return table;
	}


// read resume file 
d3.tsv("../results/statistics_FuzzPro.fuzz.tsv",d3.autoType).then(function(data) {
		
	// render the table(s)
	tabulate(data); 
});