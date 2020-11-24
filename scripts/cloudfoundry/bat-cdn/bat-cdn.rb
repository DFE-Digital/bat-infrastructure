#!/usr/bin/env ruby
require 'yaml'
require 'json'

_env = ARGV[0]

input = YAML.load_file('cdn-config.yml')

output = {
    "headers" => input[_env]["headers"],
    "domain" => input[_env]["domain"].join(",")
}

cmd = "cf update-service bat-cdn-#{_env} -c '#{output.to_json}'"

puts cmd
