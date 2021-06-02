//	filter no keep only distinc values in an array
distinct = (value, index, self) => {
	return self.indexOf(value) === index;
}

//////////////////////////////////////////////
// function to make intersection between two array of objects based on the sequence name
// return : a filtered version of allResults based on rule allResults.el.Sequence == resumeResults.all.prot_id
// allResults : array of object with sequence identifier attribute 'Sequence', this table will be filtered end returned
// resumeResults : array of object with sequence identifier attribute 'prot_id', this table will be used as filter 
function filterResultsOfInterest(allResults, resumeResults){
		
	var resultsOfInterest = allResults.filter(function(el) {
	      return resumeResults.map( d => d.prot_id).indexOf(el.Sequence) > -1	  
	});
	
	return resultsOfInterest;
}

//////////////////////////////////
// calcul height of the chart (whiout margins)
// return : interger
// resumeResults : array object containing the resume file 
// selectedGenome : selected genome
// minHeightPeerSequence : minimal height peer sequence in chart
function calcChartHeight(resumeResults, selectedGenome, minHeightPeerSequence){
	var displayedResults = resumeResults.filter( d => d.genome == selectedGenome);
	return displayedResults.length*minHeightPeerSequence;
}

//////////////////////////////////
// function to make intersection between two array of objects based on the genome name
// return : a filtered version of allResults based on rule resultsOfInterest.Genome == selectedGenome
// resultsOfInterest : array object containing the results of interest
// selectedGenome : selected genome
// minHeightPeerSequence : minimal height peer sequence in chart
function selectResultsToDisplay(resultsOfInterest, selectedGenome){
	var selectedResults = resultsOfInterest.filter(function(el) {
	      return el.Genome == selectedGenome;
	});
	return selectedResults;
}

//////////////////////////////////
// function to provide the list of sequences to display
// return : a array of sequence name
// resumeResults : array object containing the resume file
// selectedGenome : selected genome
function selectSequencesToDisplay(resumeResults, selectedGenome){
	var displayedSequences = resumeResults.filter(function(el){
		return el.genome == selectedGenome
	});
	return displayedSequences;
}

//////////////////////////////////////////////
// function to define y axis scaleBand
// return : y scaleBand
// displayedSequences: array of distinct sequences ID
// height : width of the chart
function calcYaxis(displayedSequences, chartHeight){
	var y = d3.scaleBand()
			  .domain(displayedSequences.map(d => d.prot_id))
			  .range([0, chartHeight])
	          .padding(0.1)
	          .round(true);
	return y;
}

//////////////////////////////////////////////
// function to define x axis scaleBand
// return : x scaleBand
// selectedResults : array of results
// width : width of the chart
function calcXaxis(selectedResults,width){
	var x = d3.scaleLinear()
			  .domain([0, d3.max(selectedResults.map(d => d.Sequence_size))])
			  .range([0, width])
			  .interpolate(d3.interpolateRound);
	return x ;
}

//////////////////////////////////////////////
// function to define display lthe content of MView file of the selected cluster
// cluster_id : identifiant of the cluster to display on MSA div
// clusters_folder : path of folder containing html clusters files
// MSA : d3.div object where the cluster will be displayed
function printMSA(cluster_id, clusters_folder, MSA){
	
	// clean actual MSA content
	MSA.selectAll("*").remove();
	
	// get corresponding html cluster file 
	d3.text( clusters_folder + "/" + cluster_id + ".html").then(function(html) {
		var mviewALN = MSA.append("div");
		// display MView file
		mviewALN.html(html);
	});
}

//////////////////////////////////////////////
// function to define display link to clustalo file of selected cluster
// cluster_id : identifier of the cluster to display on MSA div
// clustal_folder : path of folder containing c files
// MSALink : d3.div object where the cluster will be displayed
function printLinkToMSA(cluster_id, clusters_folder, clustal_folder, MSALink){

	// clean actual MSALink content
	MSALink.selectAll("*").remove();
	
	// get corresponding html cluster file 
	var links = MSALink.append("div");
	// link to clustal file		
	links.append("span")
	.append("a")
	.attr("href", clustal_folder + "/" + cluster_id + ".clustalo")
	.text("Clustal file ")
	.append("img")
	.attr("src","img/file-earmark-medical.svg")
	.attr("width","16px");
	
	// link to MView HTML file
	links.append("span")
	.style("margin-left","10px")
	.append("a")
	.attr("href", clusters_folder + "/" + cluster_id + ".html")
	.text("MView file ")
	.append("img")
	.attr("src","img/file-richtext.svg")
	.attr("width","16px");
	links.append("br");

}

//////////////////////////////////
// general constantes 
minHeightPeerSequence=50;


function print_results() {

    //////////////////
    // create link to file in download_statistics element
    var link =  d3.select('#download_resume_file')
                   .append("a")
                   .attr("href", "../results/all_genomes_fuzzpro_results.resume.tsv")
                   .text("FuzzPro resume file ")
                   .append("img")
                   .attr("src","img/file-earmark-spreadsheet.svg")
                   .attr("width","16px");

    ////////////////
	// Create chart

    // Define margin
	margin = ({top: 20, right: 40, bottom: 0, left: 320});

	
	Promise.all([
		d3.tsv("../results/all_results_FuzzPro.fuzz.tsv",d3.autoType),
		d3.tsv("../results/all_genomes_fuzzpro_results.resume.tsv",d3.autoType)
		]).then(function(files) {
		
		const allResults = files[0] ;
		const resumeResults = files[1] ;
		
		// extract subdata to display 
		const resultsOfInterest = filterResultsOfInterest(allResults, resumeResults);
		
		// create the non-redundant list of genomes
		const genomes = resumeResults.map(d => d.genome).filter(distinct);
		
		// initialize selected species
		var selectedGenome = genomes[0] ;
		// initialize selected sequences
		var displayedSequences = selectSequencesToDisplay(resumeResults, selectedGenome);
		// initialize selected results
		var selectedResults = selectResultsToDisplay(resultsOfInterest,selectedGenome);
		
		
		// Define plot size
		const width = 1200;
		var chartHeight = calcChartHeight(resumeResults, selectedGenome, minHeightPeerSequence);
		
		// create svg object
		var scatter_area
		var svg = d3.select("#scatter_area")
						.append("svg")
						.attr("viewBox", [0, 0, width + margin.right + margin.left, chartHeight + margin.top + margin.bottom])
						.attr("id", "mainChart")
						.append("g")
						.attr("transform","translate(" + margin.left + "," + margin.top + ")");
		
		// define Y Axis
		var y = d3.scaleBand(); // y axis scaleBand
		/////////////////////////////
		// function to (re-)init Y axis values
		initYAxisValues = function(){
			y = calcYaxis(displayedSequences, chartHeight); // define ySacle foreach sequence
		}	
		// define X Axis
		var x = d3.scaleLinear()
		/////////////////////////////
		// function to (re-)init X axis values
		initXAxisValues = function(){
			x = calcXaxis(selectedResults,width);
		}
		/////////////////////////////
		// function to (re-)init axis values
		initAxisValues = function(){
			initXAxisValues(); // init x axis
			initYAxisValues(); // init Y axis
		}
		
		// init Axis
		initAxisValues();
		
		// define MSA part
		var MSALink = d3.select("#download_MSA")
					.append("div")
		// define MSA part
		var MSA = d3.select("#MSA")
					.append("div")
		
		/////////////////////////////
		// function to print chart //
		/////////////////////////////
		var printChart = function(){
							
			// put background color
			svg.append("rect")
				.attr("width", "100%")
				.attr("height", "100%")
				.attr("fill", "white");  

			// define padding inside chart
			paddingX = 30;
			paddingY = ((chartHeight - margin.bottom)-(margin.top))/(2*displayedSequences.length);
						
			// add x axis
			svg.append("g")
				.style("font", "12px sans-serif")
				.attr("transform", "translate("+ paddingX + ",0)")
				.call(d3.axisTop(x).ticks(null))
				.call(g => g.selectAll(".tick line").clone().attr("stroke-opacity", 0.1).attr("y2", chartHeight - margin.bottom))
				.call(g => g.selectAll(".domain").remove());	
			
			// underline query with shape compatible with global pattern
			svg.append("g")
				.selectAll("rect")
				.data(displayedSequences.filter(function(d){return d.global_pattern_RBVR == "Yes"}).map(d => d.prot_id))
				.join("rect")
			    .attr("x",-margin.left +10)
			    .attr("y", d => y(d) + y.bandwidth()/4 )
				.attr("width", margin.left -15 )
				.attr("height", y.bandwidth()/2)
				.attr("fill", "yellow")
				.attr("opacity",0.7);  
			   
			   
			
			// add y axis
			svg.append("g")
				.style("font", "14px sans-serif")
				.call(d3.axisLeft(y))
				.call(g => g.selectAll(".domain").remove());

			// Add a tooltip div. Here I define the general feature of the tooltip: stuff that do not depend on the data point.
			// Its opacity is set to 0: we don't see it by default.
			var tooltip = d3.select("#scatter_area")
							.append("div")
							.style("opacity", 0)
							.attr("class", "tooltip")
							.style("background-color", "white")
							.style("border", "solid")
							.style("border-width", "1px")
							.style("border-radius", "5px")
							.style("padding", "10px")

			// A function that change this tooltip when the user hover a point.
			// Its opacity is set to 1: we can now see it. Plus it set the text and position of tooltip depending on the datapoint (d)
			var patternMouseOver = function(event, d) {
				tooltip.style("opacity", .9)
				       .html("Pattern_name: " + d.Pattern_name + "<br>observed_seq: " + d.observed_seq + "<br>start: " + d.start + "<br>stop: " + d.stop)
				       .style("left", (event.pageX + 5) + "px") 
				       .style("top", (event.pageY -28 ) + "px")
			}

			// A function that change this tooltip when the leaves a point: just need to set opacity to 0 again
			var patternMouseLeave = function(event, d) {
				tooltip.style("opacity", 0)
				 	   .style("left", width + "px") 
				 	   .style("top", chartHeight + "px")
			}
			
			// A function that change this tooltip when the user hover a point.
			// Its opacity is set to 1: we can now see it. Plus it set the text and position of tooltip depending on the datapoint (d)
			var sequenceMouseOver = function(event, d) {
				tooltip.style("opacity", .9)
				       .html(d.annot)
				       .style("left", (event.pageX + 10) + "px") 
				       .style("top", (event.pageY + 10 ) + "px")
			}

			// A function that change this tooltip when the leaves a point: just need to set opacity to 0 again
			var sequenceMouseLeave = function(event, d) {
				tooltip.style("opacity", 0)
				 	   .style("left", width + "px") 
				 	   .style("top", chartHeight + "px")
			}
			
			// add seqs lines corresponding to seq size
			svg.append("g")
				.selectAll("g")
				.data(selectedResults)
				.join("g")
				.attr("transform", d => `translate(0,${y(d.Sequence)+paddingY})`)
				.append("line")
				.attr("stroke", "#aaa")
				.attr("stroke-width", "2px")
				.attr("transform", "translate(" + paddingX  + ",0)")
				.attr("x1", x(0))
				.attr("x2", d => x(d.Sequence_size));

			// plots patterns 
						
			// plot BVM01 data in blue
			svg.append("g")
				.attr("stroke", "#000")
				.attr("stroke-opacity", 0.3)
				.selectAll("dot")
				.data(selectedResults.filter(function(el){
					return el.Pattern_name == "BVMO1" }))
				.enter()
				.append("circle")
				.attr("transform", "translate(" + paddingX  + ",0)")
				.attr("cx", d => x(d.start))
				.attr("cy", d => y(d.Sequence)+paddingY)
				.attr("fill", "blue")
				.attr("r", 9)
				.style("opacity", 0.8)
				.on("mouseover", patternMouseOver )
				.on("mouseout",  patternMouseLeave );

			// plot BVM02 data in red
			svg.append("g")
				.attr("stroke", "#000")
				.attr("stroke-opacity", 0.3)
				.selectAll("circle")
				.data(selectedResults.filter(function(el){
					return el.Pattern_name == "BVMO2" }))
				.join("circle")
				.attr("transform", "translate(" + paddingX  + ",0)")
				.attr("cx", d => x(d.start))
				.attr("cy", d => y(d.Sequence)+paddingY)
				.attr("fill", "red")
				.style("opacity", 0.8)
				.attr("r", 9)
				.on("mouseover", patternMouseOver )
				.on("mouseout", patternMouseLeave );

			// plot Rossman data in green
			svg.append("g")
				.attr("stroke", "#000")
				.attr("stroke-opacity", 0.3)
				.selectAll("circle")
				.data(selectedResults.filter(function(el){
					return el.Pattern_name == "Rossmann" }))
				.join("circle")
				.attr("transform", "translate(" + paddingX  + ",0)")
				.attr("cx", d => x(d.start))
				.attr("cy", d => y(d.Sequence)+paddingY)
				.attr("fill", "green")
				.style("opacity", 0.8)
				.attr("r", 6)
				.on("mouseover", patternMouseOver )
				.on("mouseout", patternMouseLeave );

			
			///////////////////////////
			// add button for tooltip to display sequence informations
			svg.append("g")
				.selectAll("svg")
				.data(displayedSequences)
				.join("svg")
				  .attr("x",0)
				  .attr("y",d => y(d.prot_id) + y.bandwidth()/2 - 8)
				  .attr("width","16")
				  .attr("height","16")
				  .attr("class","bi bi-info-circle-fill")
				  .attr("fill","#aaa")
				  .attr("xmlns","http://www.w3.org/2000/svg")
				  .append("path")
					.attr("fill-rule","evenodd")
					.attr("d","M8 16A8 8 0 1 0 8 0a8 8 0 0 0 0 16zm.93-9.412l-2.29.287-.082.38.45.083c.294.07.352.176.288.469l-.738 3.468c-.194.897.105 1.319.808 1.319.545 0 1.178-.252 1.465-.598l.088-.416c-.2.176-.492.246-.686.246-.275 0-.375-.193-.304-.533L8.93 6.588zM8 5.5a1 1 0 1 0 0-2 1 1 0 0 0 0 2z")
					.on("mouseover", sequenceMouseOver )
					.on("mouseout", sequenceMouseLeave );

			
			///////////////////////////
			// add button to display MSA of corresponding cluster
			var clusterButtons = svg.append("g")
				.selectAll("svg")
				.data(displayedSequences.filter(function(d){return d.cluster != "-"}))
				.join("svg")
				  .attr("x", -15)
				  .attr("y", d => y(d.prot_id) + 1.5*paddingY - 2)
				  .attr("width","25")
				  .attr("height","25")
			      .attr("class","bi bi-caret-down-fill")
				  .attr("fill","#2378ae")
				  .attr("xmlns","http://www.w3.org/2000/svg")
				  .append("path")
					      .attr("fill-rule","evenodd")
					      .attr("d","M7.247 11.14L2.451 5.658C1.885 5.013 2.345 4 3.204 4h9.592a1 1 0 0 1 .753 1.659l-4.796 5.48a1 1 0 0 1-1.506 0z")
						  .on("click", function(event, d) { 
						       printMSA(d.cluster, "./", MSA);
						       printLinkToMSA(d.cluster, "./" , "../clustalo/", MSALink)})
					      .on("mouseover", function(event, d) {d3.select(this).attr("fill", "#42365c")})
					      .on("mousemove", function(event, d) { d3.select(this).attr('fill', '#42365c') } )
					      .on("mouseleave", function(event, d) { d3.select(this).attr('fill', '#2378ae') } );

			svg.append("g")
			.selectAll("text")
			.data(displayedSequences.filter(function(d){return d.cluster != "-"}))
			.join("text")
			   .attr("fill", "black")
			   .attr("x", -20)
			   .attr("y", d => y(d.prot_id) + 1.5*paddingY + 5)
		       .attr("dy", "0.35em")
			   .attr("font-family", "sans-serif")
			   .attr("font-size", "12")
			   .attr("text-anchor", "end")
			   .text(d => "view MSA " + d.cluster + " (" + d.nb_seqs_in_cluster + " seqs)" );			
		}
		
		printChart();
		
        ////////////////////////////////
		// clean all chart elements 
		cleanChartElements = function(){
			svg.selectAll("*").remove();
		}

        ////////////////////////////////
		// rezise main chart
		updateMainChartDimensions = function(){
			d3.select("#mainChart")
			   .attr("viewBox", [0, 0, width + margin.right + margin.left, chartHeight + margin.top + margin.bottom]);
		}
		
		////////////////////////////////
		// Combo box for Genome selection
		var selectGenome = d3.select("div#select-genome")
		                     .append('select')
		                     .on('change',  function(d) {
		                    	  // assign selected value to selectedGenome global var
						 		  selectedGenome = d3.select(this).property("value");
						 		  // recalcul main chart height
						 		  chartHeight = calcChartHeight(resumeResults, selectedGenome, minHeightPeerSequence);
						 		  // update results dataset 
						 		  selectedResults = selectResultsToDisplay(resultsOfInterest,selectedGenome);
						 		  // update selected sequences
						 		  displayedSequences = selectSequencesToDisplay(resumeResults, selectedGenome);
						 		  // clean chart elements
						 		  cleanChartElements();
						 		  // re-init Axis values
						 		  initAxisValues()
						 		  // resize main chart height
						 		  updateMainChartDimensions();
						 		  // print main chart
						 		  printChart();
						      });
		
		// add the options to the button
		selectGenome // Add a button
			.selectAll('myOptions') // Next 4 lines add one option peer genome
		 	.data(genomes)
		 		.enter()
		 		.append('option')
		 		.text(function (d) { return d; }) // text showed in the menu
		 		.attr("value", function (d) { return d; }); // corresponding value returned by the button	 
			
	})
	
}

// render the table(s)
print_results(); 
