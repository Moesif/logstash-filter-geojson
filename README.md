# logstash-filter-geojson

Parses event request.body and response.body jsons recursively and extracts geo_points to separate paths request.geo_fields.body
and response.geo_fields.body.

Geo_points are extracted matching below criteria
- GeoJson format
    - Geojson format consisting of type and coordinates. type can point, line, polygon, etc.
    - For non single points like lines and polygons, centroid is calculated(averaging of coordinates in each dimension)
    - For multipolygons, multi line strings, centroid is calculated for each polygon/line string and result will be array of geo_points
- Any JSON Object containing the key sets (ignore case):
     `{"lat", "lon"}` OR `{"latitude", "longitude"}` OR `{"lat", "lng"}` (Google format)
- Key name of `location`, `latlng` (mapquest and google), `coordinates`, `position` or starts with `geo` AND the value is an array or string.
    - If string value starts with "POINT", then parse as "POINT (-71.34 41.12)"
    - Else parse as "lat, lon" if a string containing, Note the order.
    - Else try parse as [lat, lon] if array.

## Usage
```
filter {
  geojson {  
  }
}
``` 
### Build plugin
* `gem build logstash-filter-geojson.gemspec`

### Install plugin
* `$LOGSTASH_HOME/bin/plugin install logstash-filter-geojson-1.0.0.gem`

Extended from https://github.com/nreese/logstash-filter-geojson

