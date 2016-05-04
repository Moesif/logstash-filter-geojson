# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# Filter to dig out GeoJSON fields for easier usage in ElasticStack.
class LogStash::Filters::GeoJSON < LogStash::Filters::Base
  GEOJSON_LAT_INDEX=1
  GEOGJSON_LON_INDEX=0

  config_name "geojson"

  public
  def register
    # Add instance variables 
  end # def register

  #Coords is an array of lon, lat pairs
  public 
  def getCenter(coords)
    count = 0
    sumLat = 0
    sumLon = 0
    coords.each do |coord|
      count += 1
      sumLat += coord[GEOJSON_LAT_INDEX]
      sumLon += coord[GEOGJSON_LON_INDEX]
    end
    puts count
    puts sumLat
    puts sumLon
    center = {
      "lat" => sumLat / count,
      "lon" => sumLon / count
    }
    return center
  end

  public
  def convertToGeopoint(geometry)
    point = nil
    if "Point".casecmp(geometry["type"]) == 0
      point = {
        "lat" => geometry["coordinates"][GEOJSON_LAT_INDEX], 
        "lon" => geometry["coordinates"][GEOGJSON_LON_INDEX]
      }
    elsif "LineString".casecmp(geometry["type"]) == 0
      point = getCenter(geometry["coordinates"])
    end
    return point
  end

  public
  def filter(event)

    if event["properties"]
      event["properties"].each do |k, v|
        event[k] = v 
      end
    end

    if event["geometry"]
      event["point"] = convertToGeopoint(event["geometry"])
    end
    
    # filter_matched should go in the last line of our successful code
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::GeoJSON
