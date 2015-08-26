Network = () ->
  # variables 
  width = $("#graph").width()
  height = $("#graph").height()
  allData = []
  curLinksData = []
  curNodesData = []
  linkedByIndex = {}
  levels = 0
  # svg groups for accessing the nodes and links display
  nodesG = null
  linksG = null
  node = null
  link = null
  maxActors = 0
  minActors = 10000000
  filterNodes = null
  
  # though all nodes will be fixed, 
  # a force directed layout is used as base 
  # layout
  layout = d3.layout.force()

  # tooltip used to display details
  tooltip = Tooltip("vis-tooltip", 230)

  # Starting point for network visualization
  # Initializes and starts visualization 
  network = (selection, data) ->
    
    # reset the filters
    filterNodes = {"years":[], "nActors":[], "nDirectors":[]}
    
    allData = setupData(data)
    
    # create our svg and groups
    vis = d3.select(selection).append("svg")
      .attr("width", width)
      .attr("height", height)
    linksG = vis.append("g").attr("id", "links")
    nodesG = vis.append("g").attr("id", "nodes")

    # setup the size of the environment
    layout.size([width, height])

    layout.on("tick", layoutTick)
        .charge(-2000)
        .linkDistance(0)

    # update loop
    update()

  # update() is called everytime a parameter changes
  # and the network needs to be reset.
  update = () ->
    # current data
    curNodesData = allData.nodes
    curLinksData = allData.links

    # since all nodes are fixed, 
    # there is no need to apply force
    updateNodes()
    updateLinks()

    # start me up!
    layout.start()

  # setup data, calculate positions and spacing
  setupData = (data) ->

    crossFilter = new PerformCrossfilter(performFilterData, data)

    # init some vars
    maxActors = 0
    minActors = 10000000
    horizontalSpacing = 15
    nodesArray = []
    idx = 1
    layerIdx = 1
    layerHeight = []
    layerWidth = []
    layerNodes = []

    # find min and max actor values
    data.layers.forEach (l) ->
      l.nodes.forEach (n) ->
        if maxActors < n.actors_count
          maxActors = n.actors_count

        if minActors > n.actors_count
          minActors = n.actors_count

    # find max height of each layer
    data.layers.forEach (l) ->
      layerHeight[layerIdx] = 0
      layerNodes[layerIdx] = 0

      l.nodes.forEach (n) ->
        if layerHeight[layerIdx] < (circleRadius(n.actors_count))
          layerHeight[layerIdx] = circleRadius(n.actors_count)

        ++layerNodes[layerIdx]
      ++layerIdx

    sumLayerHeight = 0
    layerHeight.forEach (c) ->
      sumLayerHeight += c

    # find optimal vertical spacing to fill whole layout space
    verticalSpacing = (height - (sumLayerHeight * 2)) / layerIdx
    initVPos =  verticalSpacing

    data.layers.forEach (l) ->
      # calculate width of all nodes of this layer
      layerWidth = 0
      l.nodes.forEach (n) ->
        layerWidth += (circleRadius(n.actors_count) * 2)

      initVPos += layerHeight[idx]

      # caluclate optimal horizontal spacing
      horizontalSpacing = (width - layerWidth) / (layerNodes[idx] + 1)
      initHPos = horizontalSpacing

      l.nodes.forEach (n) ->
        # set radius of node
        n.radius = circleRadius(n.actors_count)
        # add radius of actual node to x position
        initHPos += n.radius
        # set coordinates
        n.x = initHPos
        n.y = initVPos
        n.fixed = true
        # update horizontal position based on node size and horizontal spacing
        initHPos += horizontalSpacing + n.radius
        nodesArray.push(n)

      # update vertical position based on actual and next layer size
      initVPos +=  verticalSpacing + layerHeight[idx]

      ++idx

    data.nodes = nodesArray

    # id's -> node objects
    nodesMap  = mapNodes(nodesArray)

    # switch links to point to node objects instead of id's
    data.links.forEach (l) ->
      l.source = nodesMap.get(l.source)
      l.target = nodesMap.get(l.target)

      # linkedByIndex is used for link sorting
      linkedByIndex["#{l.source.id},#{l.target.id}"] = 1

    data

  circleRadius = (val) ->
    radius = ((val - minActors) / (maxActors - minActors + 1)) * (50 - 15) + 15
    radius
            
  # Map node id's to node objects.
  mapNodes = (nodes) ->
    nodesMap = d3.map()
    nodes.forEach (o) ->
      nodesMap.set(o.id, o)
    nodesMap

  # Given two nodes a and b, returns true if
  # there is a link between them.
  # Uses linkedByIndex initialized in setupData
  neighboring = (a, b) ->
    linkedByIndex[a.id + "," + b.id] or
      linkedByIndex[b.id + "," + a.id]

  updateCenters = (artists) ->
    if layout == "radial"
      groupCenters = RadialPlacement().center({"x":width/2, "y":height / 2 - 100})
        .radius(300).increment(18).keys(artists)

  performFilterData = (filterData) ->
    filterNodes = filterData
    link.remove()
    node.remove()
    update()

  # enter/exit display for nodes
  updateNodes = () ->
    node = nodesG.selectAll("circle.node")
      .data(curNodesData, (d) -> d.id)

    node.enter().append("circle")
      .attr("class", "node")
      .attr("x", (d) -> d.x) 
      .attr("y", (d) -> d.y)
      .attr("r", (d) -> d.radius)
      .style("fill", (d) ->
      
        nodecolor = "steelblue"
        
        if filterNodes["nDirectors"].length==0 || (d.directors_count in filterNodes["nDirectors"])
          nodecolor = "steelblue"
        else
          nodecolor = "#ddd"
            
        if filterNodes["years"].length>0 && (d.year < filterNodes["years"][0] || d.year > filterNodes["years"][1] )
          nodecolor = "#ddd"
      
        if filterNodes["nActors"].length>0 && (d.actors_count < filterNodes["nActors"][0] || d.actors_count > filterNodes["nActors"][1] )
          nodecolor = "#ddd"

        nodecolor
      )
      .style("stroke", (d) -> strokeFor(d))
      .style("stroke-width", 1.0)

    node.on("mouseover", showDetails)
      .on("mouseout", hideDetails)

    node.exit().remove()

  # enter/exit display for links
  updateLinks = () ->
    link = linksG.selectAll("line.link")
      .data(curLinksData, (d) -> "#{d.source.id}_#{d.target.id}")
    link.enter().append("line")
      .attr("class", "link")
      .attr("stroke", "#ddd")
      .attr("stroke-opacity", 0.8)
      .style("stroke-width", (d) -> 
        linkstrength = d.weight * 4
        if (linkstrength <= 0)
          1
        else if (linkstrength > 20)
          20
        else
          linkstrength)
      .attr("x1", (d) -> d.source.x)
      .attr("y1", (d) -> d.source.y)
      .attr("x2", (d) -> d.target.x)
      .attr("y2", (d) -> d.target.y)

      link.on("mouseover", showLinkDetails)
       .on("mouseout", hideLinkDetails)
      
    link.exit().remove()

  # tick function for layout
  layoutTick = (e) ->
    node
      .attr("cx", (d) -> d.x)
      .attr("cy", (d) -> d.y)

    link
      .attr("x1", (d) -> d.source.x)
      .attr("y1", (d) -> d.source.y)
      .attr("x2", (d) -> d.target.x)
      .attr("y2", (d) -> d.target.y)

  # Helper function that returns stroke color for
  # particular node.
  strokeFor = (d) ->
    if (d.id in filterNodes)
      d3.rgb("#ddd").darker().toString()
    else
      d3.rgb("#steelblue").darker().toString()

  # Mouseover function for links
  showLinkDetails = (d,i) ->
    content = '<p class="main">'
    d.actors.forEach (a) ->
      content += a.name + '<br>'
    content +=  '</span></p>'
    
    tooltip.showTooltip(content,d3.event)
    
    if link
      link.attr("stroke", (l) ->
        if l.source == d.source and l.target == d.target then "#555" else "#ddd"
      )
        .attr("stroke-opacity", (l) ->
          if l.source == d.source and l.target == d.target then 1.0 else 0.8
        )
    
    # highlight connected nodes
    node.style("stroke", (n) ->
      if (n.id == d.source.id or n.id == d.target.id) then "#555" else strokeFor(n))
      .style("stroke-width", (n) ->
        if (n.id == d.source.id or n.id == d.target.id) then 4.0 else 1.0)
 
  # Mouseout function for links
  hideLinkDetails = (d,i) ->
    tooltip.hideTooltip()
    
    if link
      link.attr("stroke", "#ddd")
        .attr("stroke-opacity", 0.8)
    
        # highlight connected nodes
    node.style("stroke", (n) -> strokeFor(n))
      .style("stroke-width", 1.0)
    
  # Mouseover function for nodes
  showDetails = (d,i) ->
    content = '<p class="main"><strong>Title:</strong> ' + d.title + '<br><strong>Year:</strong> ' + d.year + '<br><strong>Actors:</strong> ' + d.actors_count + '<br><strong>Directors:</strong> ' + d.directors_count + '</span></p>'
    tooltip.showTooltip(content,d3.event)

    # higlight connected links
    if link
      link.attr("stroke", (l) ->
        if l.source == d or l.target == d then "#555" else "#ddd"
      )
        .attr("stroke-opacity", (l) ->
          if l.source == d or l.target == d then 1.0 else 0.8
        )

    # highlight neighboring nodes
    node.style("stroke", (n) ->
      if (n.searched or neighboring(d, n)) then "#555" else strokeFor(n))
      .style("stroke-width", (n) ->
        if (n.searched or neighboring(d, n)) then 4.0 else 1.0)
  
    # highlight the node being moused over
    d3.select(this).style("stroke","#555")
      .style("stroke-width", 4.0)

  # Mouseout function for noded
  hideDetails = (d,i) ->
    tooltip.hideTooltip()
    # watch out - don't mess with node if search is currently matching
    node.style("stroke", (n) -> if !n.searched then strokeFor(n) else "#555")
      .style("stroke-width", (n) -> if !n.searched then 1.0 else 2.0)
    if link
      link.attr("stroke", "#ddd")
        .attr("stroke-opacity", 0.8)

  # Final act of Network() function is to return the inner 'network()' function.
  return network
  
window.Network = Network