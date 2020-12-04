Gem::Specification.new do |s|
  s.name = 'logstash-filter-geojson'
  s.version         = '1.0.0'
  s.licenses = ['Apache-2.0']
  s.summary = "Logstash filter to transform geojson into a more ElasticSearch friendly format"
  s.description     = "This gem is a Logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install gemname. This gem is not a stand-alone program"
  s.authors = ["Nathan Reese"]
  s.email = 'reese.nathan@gmail.com'
  s.homepage = "https://github.com/nreese/logstash-filter-geojson"
  s.require_paths = ["lib"]

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core", ">= 2.0.0"
  s.add_runtime_dependency "offline_geocoder"
  s.add_development_dependency 'logstash-devutils'
end
