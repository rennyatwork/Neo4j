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

// Vancouver - Montreal in up to 5 hops
match  (c1:City{cityName:"Vancouver"})-[r*1..5]-(c2:City{cityName:"Montreal"})
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

//------------- community-------------
/// use of gds.util.asNode(nodeId)
// wcc
call gds.wcc.stream("everything")
yield  nodeId, componentId
return gds.util.asNode(nodeId) as name, componentId


// louvain
CALL gds.louvain.stream('myGraph')
YIELD nodeId, communityId, intermediateCommunityIds
RETURN gds.util.asNode(nodeId).name AS name, communityId, intermediateCommunityIds
ORDER BY name ASC


// article rank
//ArticleRank is a variant of the Page Rank algorithm, which measures the transitive influence of nodes.
CALL gds.articleRank.stream('distance')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).cityName AS name, score
ORDER BY score DESC, name ASC

size(lstName) as lstSize

//------------------------------

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

//-------------centrality
// betweeness
call gds.betweenness.stream("everything")
yield nodeId, score
RETURN gds.util.asNode(nodeId).cityName , score
ORDER BY score DESC

//degree centrality
CALL gds.degree.stream('everything')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).cityName as cityName, score AS degree
ORDER BY degree DESC, cityName ASC
//-----------------------------


//------------- path
//shortest path (djikstra)
MATCH (from:City{cityName:'Montreal'}), (to:City{cityName:'Vancouver'})
CALL apoc.algo.dijkstra(from, to, 'is_connected', 'distance') yield path as path, weight as weight
RETURN path, weight

// all simple paths (long to run)
MATCH (from:City{cityName:'Montreal'}), (to:City{cityName:'Toronto'})
CALL apoc.algo.allSimplePaths(from, to, 'is_connected', 4) yield path
RETURN *


//----------------------
