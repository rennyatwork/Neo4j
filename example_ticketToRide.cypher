//see this file https://steamcdn-a.akamaihd.net/steam/apps/108200/ss_03dcd94a3632504fbdfa92cc769c7f05913f55ad.1920x1080.jpg?t=1545399044

// show constraints
show constraints

// drop constraint
drop constraint <constraintName>



// creating constraint
create constraint pkCity
for (c:City)
require c.cityName is unique

//seeing csv output
load csv with headers from "https://raw.githubusercontent.com/rennyatwork/GeoPlot/master/DataSets/ticketToRide_edges.csv" as row
fieldterminator ';'
with row
return 
row.orig
, apoc.convert.toFloat(row.orig_lon) as orig_lon
, apoc.convert.toFloat(row.orig_lat) as orig_lat
, row.dest
, apoc.convert.toFloat(row.dest_lon) as dest_lon
, apoc.convert.toFloat(row.dest_lat) as dest_lat
, apoc.convert.toInteger(row.distance) as dist
, row.color
, row
limit 4

// // Inserting data
// call apoc.periodic.iterate('query returning value'
// , 'query operating on returned value'
// , {batchSize, parallel})
call apoc.periodic.iterate(
"load csv with headers from \"https://raw.githubusercontent.com/rennyatwork/GeoPlot/master/DataSets/ticketToRide_edges.csv\" as row
fieldterminator ';'
with row
return row"
, "with row
merge (orig:City{
cityName:row.orig
, lat:apoc.convert.toFloat(row.orig_lat) 
, lon:apoc.convert.toFloat(row.orig_lon) 
})

merge (dest:City{
cityName:row.dest
, lat:apoc.convert.toFloat(row.dest_lat) 
, lon:apoc.convert.toFloat(row.dest_lon) 
})

merge (orig)-[:is_connected{distance:row.distance, color:row.color}]-(dest)
"
, {batchSize:100, parallel:false}
)

/// show projections
call gds.graph.list()

//node degree
match (c1:City{cityName:"Montreal"})
return apoc.node.degree(c1)

// cities at 3 hops from Montreal
match (c1:City{cityName:"Montreal"})-[*3]-(c2)
return *

match (c1:City{cityName:"Montreal"})-[r*3]-(c2)
return *

//explain
// If you want to see the execution plan but not run the statement, prepend your Cypher statement with EXPLAIN
explain match (c1:City{cityName:"Montreal"})-[r*2]-(c2)
return *

// profile
profile match (c1:City{cityName:"Montreal"})-[r*2]-(c2)
return *

/// create projection
call gds.graph.project("everything", "*", "*")
yield graphName as graph, nodeProjection, nodeCount as nodes, relationshipProjection, relationshipCount as rels

/// example wcc
/// only one comunity with 35 nodes
call gds.wcc.stream("everything")
yield nodeId, componentId
with nodeId, componentId
return distinct(componentId), count(nodeId) as size

/// creating new projection
call gds.graph.project(
'distance'
, '*'
, 'is_connected'
, {relationshipProperties:'distance'}
)

/// use of gds.util.asNode(nodeId)
call gds.wcc.stream("everything")
yield  nodeId, componentId
return gds.util.asNode(nodeId) as name, componentId

/// If nedd be convert distance to integer
match ()-[r]-()
set r.distance=apoc.convert.toInteger(r.distance)

/// with threshold 2, we find 3 communities
/// threshold: greater than (not greater or equal)
call gds.wcc.stream('distance'
,{
	relationshipWeightProperty:'distance'
    , threshold:2
}
)
yield nodeId, componentId
with  componentId, collect(gds.util.asNode(nodeId).cityName) as lstNode
return componentId, lstNode
