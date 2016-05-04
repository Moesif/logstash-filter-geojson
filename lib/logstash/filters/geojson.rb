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
  def filter(event)

    if event["properties"]
      event["properties"].each do |k, v|
        event[k] = v 
      end
    end
    
    # filter_matched should go in the last line of our successful code
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::GeoJSON
