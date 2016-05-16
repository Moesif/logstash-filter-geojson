# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# Filter to dig out GeoJSON fields for easier usage in ElasticStack.
class LogStash::Filters::GeoJSON < LogStash::Filters::Base
  PROPERTIES_KEY="properties"
  GEOMETRY_KEY="geometry"
  GEOJSON_LAT_INDEX=1
  GEOGJSON_LON_INDEX=0

  config_name "geojson"

  config :properties_dig_level, :validate => :number, :default => 1

  config :properties_ignore_list, :validate => :array, :default => []

  config :geometry_centroid_key, :validate => :string, :default => "centroid"

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
  def dig(k, v, nestLevel, digLevel, existingKeys)
    @logger.debug("flattening, remaining levels: " + digLevel.to_s + ", key: " + k + ", value: " + v.to_s + ", type: " + v.class.to_s)
    if (digLevel != 0) && (v.is_a? Hash)
      nested = {}
      allKeys = existingKeys.clone #keys passed in plus keys pulled from nested objects
      v.each do |nestedKey, nestedVal|
        if !@properties_ignore_list.include? nestedKey
          subNested = dig(nestedKey, nestedVal, nestLevel+1, digLevel - 1, allKeys)
          allKeys = allKeys.concat(subNested.keys)
          nested = nested.merge(subNested)
        end
      end
      return nested
    else
      if existingKeys.include? k
        return {k + "_level" + nestLevel.to_s => v}
      else
        return {k => v}
      end
    end
  end

  public
  def filter(event)
    if event[PROPERTIES_KEY] && @properties_dig_level != 0
      props = dig(
        "props", 
        event[PROPERTIES_KEY], 
        0,
        @properties_dig_level,
        event.to_hash_with_metadata.keys)
      @logger.debug("flattened properties: " + props.to_s)
      props.each do |k, v|
        event[k] = v
      end
      event.remove(PROPERTIES_KEY)
    end

    if event[GEOMETRY_KEY]
      event[@geometry_centroid_key] = convertToGeopoint(event[GEOMETRY_KEY])
    end
    
    # filter_matched should go in the last line of our successful code
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::GeoJSON
