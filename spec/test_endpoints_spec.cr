require "../src/owocr.cr"
require "spec"
require "http"
require "random"

# Configuration for the spec
check_file_data = true
image_file_name = "image.png"
shorten_url = "https://duckduckgo.com/"
# End configuration

random = Random.new

describe OwO::WhatsThis do
  token = ENV["OWO_TOKEN"]?
  raise Exception.new "no token in ENV[OWO_TOKEN]" if token.nil?
  inst = OwO::WhatsThis.new token
  shortened_id = inst.shorten shorten_url
  puts "https://owo.whats-th.is/" + shortened_id
  image_id = inst.upload(OwO::UploadData.new File.new "image.png")
  raise Exception.new "couldn't upload!" if image_id.nil?
  image_id = image_id.url
  puts "https://owo.whats-th.is/" + image_id
  if check_file_data
    response = HTTP::Client.get "https://owo.whats-th.is/" + image_id
    raise Exception.new "couldn't get https://owo.whats-th.is/" + image_id + "!" if response.status_code != 200
    raise Exception.new "the data on each part is inequal" if response.body != File.read image_file_name
    puts "data is equal!"
  end
  bytes = random.random_bytes 1024
  bytes_id = inst.upload(OwO::UploadData.new bytes, "data.bin")
  raise Exception.new "couldn't upload!" if bytes_id.nil?
  bytes_id = bytes_id.url
  puts "https://owo.whats-th.is/" + bytes_id
  if check_file_data
    response = HTTP::Client.get "https://owo.whats-th.is/" + bytes_id
    raise Exception.new "couldn't get https://owo.whats-th.is/" + bytes_id + "!" if response.status_code != 200
    raise Exception.new "the data on each part is inequal" if response.body != String.new(bytes)
    puts "byte data is equal!"
  end
end
