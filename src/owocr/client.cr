require "./version.cr"
require "json"
require "uri"
require "http"
require "cossack"
require "./contenttype.cr"
require "./uploadedfile.cr"

module OwO
  API_URL    = "https://api.awau.moe"
  USER_AGENT = "WhatsThisClient (https://github.com/whats-this/owocr, " + VERSION + ")"

  class WhatsThis
    def initialize(@token : String, @user_agent : String = USER_AGENT, @api_url : String = API_URL)
      raise Exceptions::InvalidToken.new if token.empty?

      @client = Cossack::Client.new do |client|
        client.headers["User-Agent"] = @user_agent
        client.headers["Authorization"] = @token
        client.use Cossack::RedirectionMiddleware
      end
    end

    def upload_data(data : Bytes, file_name : String, content_type : String)
      raise Exceptions::TooLarge.new if data.size > 100*1024*1024
      io = IO::Memory.new
      boundary = HTTP::Multipart.generate_boundary
      multipart = HTTP::Multipart::Builder.new(io, boundary)
      multipart.body_part HTTP::Headers{
        "Content-Disposition" => "form-data; name=\"files[]\"; filename=\"" + file_name + "\"",
        "Content-Type"        => content_type,
      }, data
      multipart.finish
      response = @client.post(@api_url + "/upload/pomf", io.to_s) do |req|
        req.headers["Content-Type"] = "multipart/form-data; boundary=" + boundary
      end
      raise Exceptions::Unauthorized.new if response.status == 401
      raise Exceptions::TooLargePayload.new if response.status == 413
      raise Exceptions::OwOInternalError.new if response.status == 500
      return UploadedFile.from_json response.body
    end

    def upload_file(data : File, contenttype : String? = nil)
      raise Exceptions::TooLarge.new if data.size > 100*1024*1024
      read = Bytes.new data.size
      data.read read
      return upload_data read, data.path.split(File::SEPARATOR).pop, OwO.content_type(data)
    end

    def shorten(url : String | URI)
      response = @client.get(@api_url + "/shorten/polr?action=shorten&url=" + url.to_s)
      raise Exceptions::Unauthorized.new if response.status == 401
      raise Exceptions::OwOInternalError.new if response.status == 500
      url = response.body.lines.first
      return url.lchop "https://awau.moe/"
    end
  end
end
