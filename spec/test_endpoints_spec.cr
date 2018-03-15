require "../src/owocr.cr"
require "spec"

describe OwO::WhatsThis do
  token = ENV["OWO_TOKEN"]?
  raise Exception.new "no token in ENV[OWO_TOKEN]" if token.nil?
  inst = OwO::WhatsThis.new token
  puts "https://owo.whats-th.is/" + inst.shorten("https://duckduckgo.com")
  puts "https://owo.whats-th.is/" + inst.upload_file(File.new "image.png").files[0].url
end
