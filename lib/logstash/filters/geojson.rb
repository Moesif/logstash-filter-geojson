# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# Filter to dig out GeoJSON fields for easier usage in ElasticStack.
class LogStash::Filters::GeoJSON < LogStash::Filters::Base
  GEOMETRY_KEY="geometry"
  GEOJSON_LAT_INDEX=1
  GEOGJSON_LON_INDEX=0

  config_name "geojson"

  public
  def register
  end # def register

  #Coords is an array of lon, lat pairs
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

  def convertToGeopoint(geometry)
    centroid = nil
    if "Point".casecmp(geometry["type"]) == 0
      centroid = {
        "lat" => geometry["coordinates"][GEOJSON_LAT_INDEX], 
        "lon" => geometry["coordinates"][GEOGJSON_LON_INDEX]
      }
    elsif "LineString".casecmp(geometry["type"]) == 0
      centroid = getCenter(geometry["coordinates"])
    elsif "Polygon".casecmp(geometry["type"]) == 0
      exteriorRing = geometry["coordinates"][0]
      #remove last point because it just closes shape and skews center
      centroid = getCenter(exteriorRing[0...-1])
    elsif "MultiPoint".casecmp(geometry["type"]) == 0
      centroid = []
      geometry["coordinates"].each do |it|
        centroid.push({
          "lat" => it[GEOJSON_LAT_INDEX], 
          "lon" => it[GEOGJSON_LON_INDEX]
        })
      end
    elsif "MultiPolygon".casecmp(geometry["type"]) == 0
      centroid = []
      geometry["coordinates"].each do |it|
        exteriorRing = it[0]
        centroid.push(getCenter(exteriorRing[0...-1]))
      end
    else
      @logger.warn("unexpected geometry: " + geometry["type"])
    end
    return centroid
  end

  # Function to parse body
  def parse_body(event, object_field, fetch_body_field, parsed_body_field, org_id, app_id)
    begin
      # Empty hash to store geo fields
      geo_fields = Hash.new
      # Fetch the request/response body
      fetched_body = event.get(fetch_body_field)
      if !fetched_body.nil?
        # Fetch the request/response object
        req_resp_object = event.get(object_field)
        # Fetch the content-type from headers
        content_type = nil
        if req_resp_object.key?('headers') && !req_resp_object['headers'].nil? && req_resp_object['headers'].key?('Content-Type')
          content_type = req_resp_object['headers']['Content-Type']
          @logger.debug('geoJsonParser: Content type -  ', content: content_type)

          # Check if the content type is application/json and body is of type Hash or Array (Json)
          if !content_type.nil? && (content_type.include? 'application/json') && (fetched_body.is_a? Hash or fetched_body.is_a? Array)
            parse_json_body(event, fetched_body, geo_fields, parsed_body_field, org_id, app_id)
          else
            # Set the parsed body object to empty hash
            @logger.debug('geoJsonParser: Content-type is not json so setting to empty array for orgId - ' << org_id << ' and appId - ' << app_id)
            event.set(parsed_body_field, geo_fields)
          end
        elsif (fetched_body.is_a? Hash && !fetched_body.key?('_raw')) || (fetched_body.is_a? Array)
          @logger.debug('geoJsonParser: Content-type header is not availabe and body is of type JSON so parsing body as JSON for orgId - ' << org_id << ' and appId - ' << app_id)
          parse_json_body(event, fetched_body, geo_fields, parsed_body_field, org_id, app_id)
        else
          @logger.debug('geoJsonParser: Content-type header is not available and body is not of type JSON so setting to empty array for orgId - ' << org_id << ' and appId - ' << app_id)
          event.set(parsed_body_field, geo_fields)
        end
      else
        # Body is empty
        @logger.debug('geoJsonParser: Body fetched from the event is empty for orgId - ' << org_id << ' and appId - ' << app_id)
        event.set(parsed_body_field, geo_fields)
      end
    rescue StandardError => e
      @logger.warn('geoJsonParser: error processing body for orgId - ' << org_id << ' and appId - ' << app_id << ' with exception - ', exception: e)
      event.set(parsed_body_field, Hash.new)
    end
  end

  # Function to parse json body
  def parse_json_body(event, body, geo_fields, parsed_body_field, org_id, app_id)
    begin
      # Process the JSON body
      process_body(body, geo_fields, org_id, app_id)
      event.set(parsed_body_field, geo_fields)
    rescue => e
      @logger.warn('geoJsonParser: error parsing JSON body for orgId - ' << org_id << ' and appId - ' << app_id << ' with exception - ', exception: e)
      event.set(parsed_body_field,  geo_fields)
    end
  end

  # Function to process body
  def process_body(body, geo_fields, org_id, app_id)
    @logger.debug('geoJsonParser: process body data for orgId - ' << org_id << ' and appId - ' << app_id)
    # extract the geo fields
    extract_geo_fields(body, geo_fields)
  end

  # Function to extract geo fields
  def extract_geo_fields(data, prefix= "", geo_fields)
    # Add dot(.) to prefix in case of nested hash
    prefixDot = !(prefix.empty? || prefix.nil?) ? prefix + '.' : ''
    # Check if the data is of type hash
    if data.is_a? Hash
      geo_point = extract_geo_point(data)
      add_to_geo_fields(geo_point, geo_fields)
      data.each do |key, value|
        if key
          sub_hash = Hash.new
          extract_geo_fields(value, prefixDot + key.to_s, sub_hash)
          if !sub_hash.empty? && key
            geo_fields[key.to_s] = sub_hash
          end
        end
      end
    # Check if the data is of type array
    elsif data.is_a? Array
      # For each element in data, recursive function to find the leaf node
      data.each { |item| extract_geo_fields(item, prefixDot, geo_fields)}
    end
  end


  def add_to_geo_fields(geo_point, geo_fields)
    if !geo_point
      return
    end
    key = "geo_point"
    if geo_fields.key?(key) && (geo_fields[key].is_a? Array)
      geo_fields[key].push(geo_point)
    elsif geo_fields.key?(key)
      geo_fields[key] = [geo_fields[key], geo_point]
    else
      geo_fields[key] = geo_point
    end
  end

  def extract_geo_point(input)
    # transform keys to lowercase
    input.transform_keys!(&:downcase)
    # check for geometry
    if input.key?("type") && input.key?("coordinates")
      return convertToGeopoint(input)
    # check for lat/lon
    elsif input.key?("lat") && input.key?("lon")
      return parse_lat_lon_from_array([input["lat"], input["lon"]])
    # check for latitude/longitude
    elsif input.key?("latitude") && input.key?("longitude")
      return parse_lat_lon_from_array([input["latitude"], input["longitude"]])
    # check for lat/lng
    elsif input.key?("lat") && input.key?("lng")
      return parse_lat_lon_from_array([input["lat"], input["lng"]])
    elsif input.key?("location")
      return parse_lat_lon(input["location"])
    elsif input.key?("latlng")
      return parse_lat_lon(input["latlng"])
    elsif input.key?("coordinates")
      return parse_lat_lon(input["coordinates"])
    elsif input.key?("position")
      return parse_lat_lon(input["position"])
    else
      input.each do |key, value|
        if key.start_with?("geo")
          point = parse_lat_lon(value)
          if point
            return point
          end
        end
      end
    end
    return nil
  rescue StandardError => e
    @logger.warn('geoJsonParser: unable to extract geo_point', data: input, exception: e)
    return nil
  end

  def parse_lat_lon(input)
    if input.is_a? String
      str_point = nil
      if input.start_with?("POINT")
       str_point = input.scan(/POINT\(([^>]*)\)/).last.first
      else
       str_point = input
      end
      coords = str_point.split(",")
      return parse_lat_lon_from_array(coords)
    elsif input.is_a? Array
      return parse_lat_lon_from_array(input)
    end
  end

  def valid_float(str)
    !!Float(str) rescue false
  end

  def parse_lat_lon_from_array(input)
    if input.length < 2
      return nil
    end
    point = nil
    if (input[0].is_a? Numeric) && (input[1].is_a? Numeric)
      point = {
        "lat" => input[0],
        "lon" => input[1]
      }
    elsif (input[0].is_a? String) && (input[1].is_a? String) && valid_float(input[0]) && valid_float(input[1])
      point = {
        "lat" => input[0].to_f,
        "lon" => input[1].to_f
      }
    end
    return point
  end

  public
  def filter(event)
    # Fetch Event OrgId
    org_id = event.get("[org_id]")
    # Fetch Event AppId
    app_id = event.get("[app_id]")
    # Request Body
    @logger.debug('geoJsonParser: Begin parsing for request body for orgId - ' << org_id << ' and appId - ' << app_id)
    parse_body(event, "[request]",  "[request][body]", "[request][geo_fields][body]", org_id, app_id)
    # Response Body
    @logger.debug('geoJsonParser: Begin parsing response body for orgId - ' << org_id << ' and appId - ' << app_id)
    parse_body(event, "[response]",  "[response][body]", "[response][geo_fields][body]", org_id, app_id)
    # Filter match event
    filter_matched(event)
  rescue StandardError => e
     @logger.warn('geoJsonParser: error while parsing geoJson', exception: e)
  end # def filter

end # class LogStash::Filters::GeoJSON
