# logstash-filter-geojson
[GeoJson](http://geojson.org/) provides an elogent solution for encoding domain agnostic geographic data. 
However, when inserting documents into ElasticSearch, the GeoJSON format is not the best fit. There are two main problems
* The GeoJSON format nests domain specific attributes under the `properties` element. ElasticSearch/kibana work work best with flatter data strutures
* The ElasticSearch geo_point is not compatiable with GeoJSON's point type

This Logstash filter transforms GeoJSON into a simpliler structure more suitable for storing in ElasticSearch.


