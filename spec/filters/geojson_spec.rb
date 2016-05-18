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
        expect(subject).not_to include("properties")
        expect(subject['stringProp']).to eq('some text')
        expect(subject['numProp']).to eq(10)
      end
    end

    describe "Point geometry" do
      geometry = {"type" => "Point", "coordinates" => [125.6, 10.1]}
      sample("geometry" => geometry) do
        expect(subject).to include("centroid")
        geoPoint = subject['centroid']
        expect(geoPoint).to include("lat")
        expect(geoPoint).to include("lon")
        expect(geoPoint['lat']).to eq(10.1)
        expect(geoPoint['lon']).to eq(125.6)
      end
    end

    describe "LineString geometry" do
      geometry = {"type" => "LineString", "coordinates" => [ [100.0, 0.0], [101.0, 1.0] ]}
      sample("geometry" => geometry) do
        expect(subject).to include("centroid")
        geoPoint = subject['centroid']
        expect(geoPoint).to include("lat")
        expect(geoPoint).to include("lon")
        expect(geoPoint['lat']).to eq(0.5)
        expect(geoPoint['lon']).to eq(100.5)
      end
    end

    describe "Polygon geometry" do
      geometry = {"type" => "Polygon", "coordinates" => [
        [ [100.0, 0.0], [101.0, 0.0], [101.0, 1.0], [100.0, 1.0], [100.0, 0.0] ]
        ]}
      sample("geometry" => geometry) do
        expect(subject).to include("centroid")
        geoPoint = subject['centroid']
        expect(geoPoint).to include("lat")
        expect(geoPoint).to include("lon")
        expect(geoPoint['lat']).to eq(0.5)
        expect(geoPoint['lon']).to eq(100.5)
      end
    end

    describe "MultiPoint geometry" do
      geometry = {
        "type" => "MultiPoint", 
        "coordinates" => [ [100.0, 0.0], [101.0, 1.0] ]
      }
      sample("geometry" => geometry) do
        expect(subject).to include("centroid")
        geoPoint = subject['centroid']
        expect(geoPoint.length).to eq(2)
        expect(geoPoint[0]['lat']).to eq(0.0)
        expect(geoPoint[0]['lon']).to eq(100.0)
        expect(geoPoint[1]['lat']).to eq(1.0)
        expect(geoPoint[1]['lon']).to eq(101.0)
      end
    end

    { "type": "MultiPoint",
    "coordinates": [ [100.0, 0.0], [101.0, 1.0] ]
    }
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

  describe "Test dig properties name collisions" do
    props = {
      "collisionKey" => "level 1", 
      "anotherCollision" => "level 1",
      "objProp" => {
        "collisionKey" => "level 2",
        "anotherCollision" => "level 2"
      }
    }

    let(:config) do <<-CONFIG
    filter {
      geojson {
        properties_dig_level => -1  
      }
    }
    CONFIG
    end
    sample("properties" => props, "collisionKey" => "level 0") do
      expect(subject).to include("collisionKey")
      expect(subject).to include("collisionKey_level1")
      expect(subject).to include("anotherCollision")
      expect(subject).to include("collisionKey_level2")
      expect(subject).to include("anotherCollision_level2")
      expect(subject['collisionKey']).to eq("level 0")
      expect(subject['collisionKey_level1']).to eq("level 1")
      expect(subject['anotherCollision']).to eq("level 1")
      expect(subject['collisionKey_level2']).to eq("level 2")
      expect(subject['anotherCollision_level2']).to eq("level 2")
    end
  end

#sibling name collisions are going to be a problem and need a new algorithm
#tackle this when it becomes a problem
=begin
  describe "Test dig properties sibling name collisions" do
    props = {
      "objProp1" => {
        "siblingKey" => "from objProp1"
      },
      "objProp2" => {
        "siblingKey" => "from objProp2"
      },
      "objProp3" => {
        "siblingKey" => "from objProp3"
      }
    }

    let(:config) do <<-CONFIG
    filter {
      geojson {
        properties_dig_level => -1  
      }
    }
    CONFIG
    end
    sample("properties" => props, "collisionKey" => "level 0") do
      expect(subject).to include("siblingKey")
      expect(subject).to include("siblingKey_2")
      expect(subject).to include("siblingKey_3")
      expect(subject['siblingKey']).to eq("from objProp1")
      expect(subject['siblingKey_2']).to eq("from objProp2")
      expect(subject['siblingKey_3']).to eq("from objProp3")
    end
  end
=end

  describe "Test properties_ignore_list config" do
    props = {
      "stringKey" => "ignore me", 
      "numProp" => 10,
      "objProp" => {
        "nestedStringProp" => "ignore me",
        "nestedNumProp" => 10.1,
      },
      "ignoreThisObj" => {
        "anotherStringKey" => "ignore my parent"
      }
    }

    let(:config) do <<-CONFIG
    filter {
      geojson {
        properties_ignore_list => ["stringKey", "nestedStringProp", "ignoreThisObj"]
        properties_dig_level => -1
      }
    }
    CONFIG
    end
    sample("properties" => props) do
      expect(subject).to include("numProp")
      expect(subject).to include("nestedNumProp")
      expect(subject).not_to include("stringKey")
      expect(subject).not_to include("nestedStringProp")
      expect(subject).not_to include("ignoreThisObj")
      expect(subject['numProp']).to eq(10)
      expect(subject['nestedNumProp']).to eq(10.1)
    end
  end

  describe "Test geometry_centroid_key config" do
    let(:config) do <<-CONFIG
    filter {
      geojson {
        geometry_centroid_key => "myCentroid"
      }
    }
    CONFIG
    end
    geometry = {"type" => "Point", "coordinates" => [125.6, 10.1]}
    sample("geometry" => geometry) do
      expect(subject).to include("myCentroid")
    end
  end

end
