# encoding: utf-8
require 'spec_helper'
require "logstash/filters/geojson"

describe LogStash::Filters::GeoJSON do
  let(:config) do <<-CONFIG
    filter {
      geojson {  
      }
    }
    CONFIG
  end

  describe "Event with no GeoJSON" do
    sample("message" => "some text") do
      expect(subject).to include("message")
      expect(subject['message']).to eq('some text')
    end
  end

  describe "Un-nest GeoJSON properties" do
    props = {"stringProp" => "some text", "numProp" => 10}
    sample("properties" => props) do
      expect(subject).to include("stringProp")
      expect(subject).to include("numProp")
      expect(subject['stringProp']).to eq('some text')
      expect(subject['numProp']).to eq(10)
    end
  end

  describe "Convert GeoJSON Point to ElasticSearch geo_point" do
    geometry = {"type" => "Point", "coordinates" => [125.6, 10.1]}
    sample("geometry" => geometry) do
      expect(subject).to include("point")
      geoPoint = subject['point']
      expect(geoPoint).to include("lat")
      expect(geoPoint).to include("lon")
      expect(geoPoint['lat']).to eq(10.1)
      expect(geoPoint['lon']).to eq(125.6)
    end
  end

end
