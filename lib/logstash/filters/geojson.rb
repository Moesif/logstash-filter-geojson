# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# Filter to dig out GeoJSON fields for easier usage in ElasticStack.
class LogStash::Filters::GeoJSON < LogStash::Filters::Base
  GEOJSON_LAT_INDEX=1
  GEOGJSON_LON_INDEX=0

  config_name "geojson"

  config :properties_dig_level, :validate => :number, :default => 1


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
    elsif "Polygon".casecmp(geometry["type"]) == 0
      exteriorRing = geometry["coordinates"][0]
      #remove last point because it just closes shape and skews center
      point = getCenter(exteriorRing[0...-1])
    end
    return point
  end

  public
  def dig(k, v, level)
    @logger.debug("flattening, remaining levels: " + level.to_s + ", key: " + k + ", value: " + v.to_s + ", type: " + v.class.to_s)
    if (level != 0) && (v.is_a? Hash)
      nested = {}
      v.each do |nestedKey, nestedVal|
        nested = nested.merge(dig(nestedKey, nestedVal, level - 1))
      end
      return nested
    else
      return {k => v}
    end
  end

  public
  def filter(event)
    if event["properties"] && properties_dig_level != 0
      props = dig("properties", event["properties"], properties_dig_level)
      @logger.debug("flattened properties: " + props.to_s)
      props.each do |k, v|
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
