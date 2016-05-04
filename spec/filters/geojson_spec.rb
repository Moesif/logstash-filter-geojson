# encoding: utf-8
require 'spec_helper'
require "logstash/filters/geojson"

describe LogStash::Filters::GeoJSON do
  describe "Set to Hello World" do
    let(:config) do <<-CONFIG
      filter {
        geojson {
          message => "Hello World"
        }
      }
    CONFIG
    end

    sample("message" => "some text") do
      expect(subject).to include("message")
      expect(subject['message']).to eq('Hello World')
    end
  end
end
