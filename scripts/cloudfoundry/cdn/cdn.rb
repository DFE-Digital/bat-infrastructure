#!/usr/bin/env ruby
require 'yaml'
require 'json'

def usage(input)
    puts "Usage: ./cdn.rb <CDN instance>"
    puts "Known CDN instances:"
    puts input.keys.select{|c| !c.include? "headers"}
    exit
end

input = YAML.load_file('cdn-config.yml')

usage(input) if ARGV.empty?

_env = ARGV[0]

output = {
    "headers" => input[_env]["headers"],
    "domain"  => input[_env]["domain"].join(","),
    "cookies" => input[_env]["cookies"],
}.select{|k,v| !v.nil? }

service=input[_env]["service"]

cmd = "cf update-service #{service} -c '#{output.to_json}'"

puts cmd
