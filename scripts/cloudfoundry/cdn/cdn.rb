#!/usr/bin/env ruby
require 'yaml'
require 'json'

def usage(input)
    puts "Usage: ./cdn.rb <create / update> <CDN instance>"
    puts "Known CDN instances:"
    puts input.keys.select{|c| !c.include? "headers"}
    exit
end

input = YAML.load_file('cdn-config.yml')

usage(input) if ARGV.empty?

_action = ARGV[0]
_env = ARGV[1]

output = {
    "headers" => input[_env]["headers"],
    "domain"  => input[_env]["domain"].join(","),
    "cookies" => input[_env]["cookies"],
}.select{|k,v| !v.nil? }

service=input[_env]["service"]

if(_action == "create")
    cmd = "cf create-service cdn-route cdn-route #{service} -c '#{output.to_json}'"
elsif (_action == "update")
    cmd = "cf update-service #{service} -c '#{output.to_json}'"
else
    usage(input)
end
puts cmd
