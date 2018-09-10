require "../src/owocr.cr"
require "spec"
require "http"
require "./constants"
require "./config"

describe OwO::WhatsThis do
  token = ENV["OWO_TOKEN"]? || raise "no token in ENV[OWO_TOKEN]"
  inst = OwO::WhatsThis.new token

  describe "shortening" do
    shortened_id = inst.shorten SHORTEN_URL
    puts "https://owo.whats-th.is/#{shortened_id}"
  end

  describe "image uploading" do
    image_id = inst.upload OwO::UploadData.new File.new IMAGE_FILE_NAME
    image_id.should be_truthy
    image_id || raise "image_id is nil" # just non-nil assertion

    image_id = image_id.url
    puts "https://owo.whats-th.is/#{image_id}"

    if CHECK_FILE_DATA
      response = HTTP::Client.get "https://owo.whats-th.is/#{image_id}"
      raise "couldn't get https://owo.whats-th.is/#{image_id}!" if response.status_code != 200
      raise "the data on each part is inequal" if response.body != File.read IMAGE_FILE_NAME
      puts "data is equal!"
    end
  end

  describe "random data upload" do
    bytes = RANDOM.random_bytes 1024
    bytes_id = inst.upload OwO::UploadData.new bytes, "data.bin"
    bytes_id.should be_truthy
    bytes_id || raise "bytes_id is nil" # just non-nil assertion

    bytes_id = bytes_id.url
    puts "https://owo.whats-th.is/#{bytes_id}"

    if CHECK_FILE_DATA
      response = HTTP::Client.get "https://owo.whats-th.is/#{bytes_id}"
      raise "couldn't get https://owo.whats-th.is/#{bytes_id}!" if response.status_code != 200
      raise "the data on each part is inequal" if response.body != String.new bytes
      puts "byte data is equal!"
    end
  end
end
