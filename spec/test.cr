require "../src/owocr.cr"

token = ENV["OWO_TOKEN"]?
raise Exception.new "no token in ENV[OWO_TOKEN]" if token.nil?
inst = OwO::WhatsThis.new token
puts inst.shorten("https://duckduckgo.com")
puts inst.upload_file(File.new "image.png").files[0].url