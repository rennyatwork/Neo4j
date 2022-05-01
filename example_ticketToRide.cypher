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

// Inserting data
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