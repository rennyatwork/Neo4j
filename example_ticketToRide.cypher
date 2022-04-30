
create constraint pkCity
for (c:City)
require c.cityName is unique
