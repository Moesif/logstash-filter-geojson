# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# Filter to dig out GeoJSON fields for easier usage in ElasticStack.
class LogStash::Filters::GeoJSON < LogStash::Filters::Base

  config_name "geojson"

  public
  def register
    # Add instance variables 
  end # def register

  public
  def convertToGeopoint(geometry)
    point = nil
    if geometry["type"] == "Point"
      point = {
        "lat" => geometry["coordinates"][1], 
        "lon" => geometry["coordinates"][0]
      }
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
