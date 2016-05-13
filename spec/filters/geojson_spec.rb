# encoding: utf-8
require 'spec_helper'
require "logstash/filters/geojson"

describe LogStash::Filters::GeoJSON do
  describe "with default config" do
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

    describe "Convert GeoJSON LineString to ElasticSearch geo_point" do
      geometry = {"type" => "LineString", "coordinates" => [ [100.0, 0.0], [101.0, 1.0] ]}
      sample("geometry" => geometry) do
        expect(subject).to include("point")
        geoPoint = subject['point']
        expect(geoPoint).to include("lat")
        expect(geoPoint).to include("lon")
        expect(geoPoint['lat']).to eq(0.5)
        expect(geoPoint['lon']).to eq(100.5)
      end
    end

    describe "Convert GeoJSON Polygon to ElasticSearch geo_point" do
      geometry = {"type" => "Polygon", "coordinates" => [
        [ [100.0, 0.0], [101.0, 0.0], [101.0, 1.0], [100.0, 1.0], [100.0, 0.0] ]
        ]}
      sample("geometry" => geometry) do
        expect(subject).to include("point")
        geoPoint = subject['point']
        expect(geoPoint).to include("lat")
        expect(geoPoint).to include("lon")
        expect(geoPoint['lat']).to eq(0.5)
        expect(geoPoint['lon']).to eq(100.5)
      end
    end
  end

  describe "Test properties_dig_level config" do
    props = {
      "stringProp" => "some text", 
      "numProp" => 10,
      "objProp" => {
        "nestedStringProp" => "more text",
        "nestedNumProp" => 10.1,
        "nestedObjProp" => {
          "nested2StringProp" => "really deep"
        }
      }
    }

    describe "Un-nest GeoJSON properties (dig level 0)" do
      let(:config) do <<-CONFIG
      filter {
        geojson {
          properties_dig_level => 0  
        }
      }
      CONFIG
      end
      sample("properties" => props) do
        expect(subject).not_to include("stringProp")
        expect(subject).not_to include("numProp")
      end
    end

    describe "Un-nest GeoJSON properties (dig level 1)" do
      let(:config) do <<-CONFIG
      filter {
        geojson {
          properties_dig_level => 1
        }
      }
      CONFIG
      end
      sample("properties" => props) do
        expect(subject).to include("stringProp")
        expect(subject).to include("numProp")
        expect(subject).to include("objProp")
        expect(subject).not_to include("nestedStringProp")
        expect(subject).not_to include("nestedNumProp")
        expect(subject).not_to include("nestedObjProp")
        expect(subject['stringProp']).to eq('some text')
        expect(subject['numProp']).to eq(10)
      end
    end

    describe "Un-nest GeoJSON properties (dig level 2)" do
      let(:config) do <<-CONFIG
      filter {
        geojson {
          properties_dig_level => 2
        }
      }
      CONFIG
      end
      sample("properties" => props) do
        expect(subject).to include("stringProp")
        expect(subject).to include("numProp")
        expect(subject).not_to include("objProp")
        expect(subject).to include("nestedStringProp")
        expect(subject).to include("nestedNumProp")
        expect(subject).not_to include("nested2StringProp")
        expect(subject['stringProp']).to eq('some text')
        expect(subject['numProp']).to eq(10)
        expect(subject['nestedStringProp']).to eq('more text')
        expect(subject['nestedNumProp']).to eq(10.1)
      end
    end

    describe "Un-nest GeoJSON properties (dig level infinate)" do
      let(:config) do <<-CONFIG
      filter {
        geojson {
          properties_dig_level => -1
        }
      }
      CONFIG
      end
      sample("properties" => props) do
        expect(subject).to include("stringProp")
        expect(subject).to include("numProp")
        expect(subject).not_to include("objProp")
        expect(subject).to include("nestedStringProp")
        expect(subject).to include("nestedNumProp")
        expect(subject).to include("nested2StringProp")
        expect(subject['stringProp']).to eq('some text')
        expect(subject['numProp']).to eq(10)
        expect(subject['nestedStringProp']).to eq('more text')
        expect(subject['nestedNumProp']).to eq(10.1)
        expect(subject['nested2StringProp']).to eq("really deep")
      end
    end

  end 
end
