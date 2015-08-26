function PerformCrossfilter (callback, data) {

  var films = [];

  for(i=0; i<data.layers.length; i++){
    for(j=0; j<data.layers[i].nodes.length; j++){      
      films.push(data.layers[i].nodes[j]);
    }
  }

  var film = crossfilter(films);
  var all = film.groupAll();


  var filterData = {
    years: [],
    nActors: [],
    nDirectors: []
  }

  var yearChart = dc.barChart("#year-chart"); 

  var year = film.dimension(function (d) {
    return d.year;
  });

  var yearGroupCount = year.group()
    .reduceCount(function(d) { return d.year; })

  maxYear = d3.max($.map(films, function(d) { return parseInt(d.year); }));
  minYear = d3.min($.map(films, function(d) { return parseInt(d.year); }));


  yearChart
    .on("filtered", function(chart, filter){
      filterData.years = [parseInt(filter[0]),parseInt(filter[1])];
      callback(filterData);

      console.log(filterData);
    })
    .width(260)
    .height(150)  
    .gap(0)
    .margins({top: 10, right: 10, bottom: 20, left: 40})
    .dimension(year)
    .group(yearGroupCount)
    .centerBar(false)  
    .x(d3.scale.linear().domain([minYear-1, maxYear+1])) 
    .elasticY(true)
    .xAxis()
      .tickFormat(function(v){      
        var text = "";
        if(parseInt(v)%10==0){
          text = v;
        }
        return text;
      }) 
      .ticks(maxYear - minYear)
    ;


  var actorChart = dc.barChart("#actor-chart");  

  var actor = film.dimension(function (d) {
    return d.actors_count;
  });

  var actorGroupCount = actor.group()
    .reduceCount(function(d) { 
      return Math.round(parseInt(d.actors_count)/20); 
    })

  maxActor = d3.max($.map(films, function(d) { return parseInt(d.actors_count); }));


  actorChart
    .on("filtered", function(chart, filter){
      filterData.nActors = [parseInt(filter[0]),parseInt(filter[1])];
      callback(filterData);
      console.log(filterData);
    })
    .width(260)
    .height(70)
    .margins({top: 10, right: 10, bottom: 20, left: 40})
    .dimension(actor)
    .group(actorGroupCount)
    .centerBar(true)    
    .gap(0)
    .x(d3.scale.linear().domain([0, maxActor+10]))
    ;    


  var directorChart = dc.rowChart("#director-chart");  

  var director = film.dimension(function (d) {
    return d.directors_count;
  });

  var directorGroupCount = director.group()
    .reduceCount(function(d) { 
      return Math.round(parseInt(d.directors_count)/20); 
    })

  directorChart
    .on("filtered", function(chart, filter){
      var nDirectors = filterData.nDirectors;  
      var hit = 0;
      for(i=0; i<nDirectors.length; i++){
        console.log("hit");
        if(nDirectors[i]==filter){
          hit = 1;
          nDirectors.splice(i, 1);
        }
      }
      if(hit==0){
        nDirectors.push(filter);
      }
      hit = 0;
      callback(filterData);
      console.log(JSON.stringify(filterData));
    })
    .width(260)
    .height(150)    
    .margins({top: 10, right: 10, bottom: 20, left: 40})
    .dimension(director)
    .group(directorGroupCount)
    .label(function (d){
      var value = d.key;
      var s = value+" Directors";
      if(value==1){
        s = value+" Director";
      }
      return s;
    })
    .elasticX(true)
    .xAxis().ticks(4)
    ;


  dc.renderAll();
}