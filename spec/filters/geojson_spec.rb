# encoding: utf-8
require 'spec_helper'
require "logstash/filters/geojson"

describe LogStash::Filters::GeoJSON do
  describe "Event with no GeoJSON" do
    let(:config) do <<-CONFIG
      filter {
        geojson {
        }
      }
    CONFIG
    end

    sample("message" => "some text") do
      expect(subject).to include("message")
      expect(subject['message']).to eq('some text')
    end
  end

  describe "Un-nest GeoJSON properties" do
    let(:config) do <<-CONFIG
      filter {
        geojson {
          
        }
      }
    CONFIG
    end

    props = {"stringProp" => "some text", "numProp" => 10}

    sample("properties" => props) do
      expect(subject).to include("stringProp")
      expect(subject).to include("numProp")
      expect(subject['stringProp']).to eq('some text')
      expect(subject['numProp']).to eq(10)
    end
  end
end
