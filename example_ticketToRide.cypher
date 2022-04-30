// creating constraint
create constraint pkCity
for (c:City)
require c.cityName is unique

//seeing csv output
load csv with headers from "https://raw.githubusercontent.com/rennyatwork/GeoPlot/master/DataSets/ticketToRide_edges.csv" as row
fieldterminator ';'
with row
return row.orig
limit 4
