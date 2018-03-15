require "./version.cr"
require "json"
require "uri"
require "http"
require "cossack"
require "./contenttype.cr"
require "./uploadedfile.cr"

module OwO
  # `API_URI` is a constant to the default OwO v1 API endpoint: https://api.awau.moe
  API_URI = "https://api.awau.moe"

  # `USER_AGENT` is the default constant User-Agent header.
  # The version is specified by `VERSION`, which changes as the wrapper updates.
  USER_AGENT = "WhatsThisClient (https://github.com/whats-this/owocr, " + VERSION + ")"

  # `WhatsThis` refers to the actual client which is to be used with the wrapper.
  # It is the entrypoint for any application wishing to use it, and is the only part of this meant to be used.
  class WhatsThis
    # Initializes a new client instance with the following data:
    #
    #  - *token* being the OwO token.
    #    The token may not have the dashes stripped and must not include any form for whitespace.
    #    If the token is empty, it will raise an `OwO::Exceptions::InvalidToken` exception.
    #  - *user_agent* being the User-Agent field.
    #    The User-Agent to be used. This is not recommended to change, as your application may be denied access to the API.
    #    It is defaulted to `OwO::USER_AGENT`.
    #  - *api_uri* being the API URI endpoint.
    #    The API endpoint URI to connect to and use while using the client.
    #    Its default value is `OwO::API_URI`.
    #
    # It in turn initializes a new `Cossack::Client` which follows redirections and has the following headers:
    #
    #  - `User-Agent` => *user_agent*
    #  - `Authorization` => *token*
    def initialize(@token : String, user_agent : String = USER_AGENT, @api_uri : String = API_URI)
      raise Exceptions::InvalidToken.new if token.empty?

      @client = Cossack::Client.new do |client|
        client.headers["User-Agent"] = @user_agent
        client.headers["Authorization"] = @token
        client.use Cossack::RedirectionMiddleware
      end
    end

    # `#upload_data` uploads the data as specified by the parameters:
    #
    #  - *data* being the data in a `Bytes` instance.
    #    This data is uploaded raw as UTF-8 to OwO.
    #    It may not include several chunks for several files to be uploaded at once.
    #  - *file_name* is the file name to be sent to OwO.
    #    In bandwidth-favouring cases, one would prefer a basic name such as `a.png`, where the extension is kept.
    #    The extension on OwO's server is gotten from this parameter.
    #  - *content_type* is the value for the Content-Type header of the file.
    #    It must be a valid MIME type, and is defaulted to "application/octet-stream".
    #
    # Under the following circumstances are exceptions raised:
    #
    #  - `OwO::Exceptions::Unauthorized` is raised if the `@token` value is deactivated.
    #  - `OwO::Exceptions::TooLargePayload` is raised if OwO changes the payload max size before this library updates.
    #  - `OwO::Exceptions::TooLarge` is raised if you upload data over the size of 100MiB.
    #  - `OwO::Exceptions::OwOInternalError` is raised if OwO has an internal error at their API.
    #
    # A 404 error is not handled by this library and may result in a panic.
    #
    # It returns an instance of `UploadedFile`.
    def upload_data(data : Bytes, file_name : String, content_type : String = "application/octet-stream")
      raise Exceptions::TooLarge.new if data.size > 100*1024*1024
      io = IO::Memory.new
      boundary = HTTP::Multipart.generate_boundary
      multipart = HTTP::Multipart::Builder.new(io, boundary)
      multipart.body_part HTTP::Headers{
        "Content-Disposition" => "form-data; name=\"files[]\"; filename=\"" + file_name + "\"",
        "Content-Type"        => content_type,
      }, data
      multipart.finish
      response = @client.post(@api_uri + "/upload/pomf", io.to_s) do |req|
        req.headers["Content-Type"] = "multipart/form-data; boundary=" + boundary
      end
      raise Exceptions::Unauthorized.new if response.status == 401
      raise Exceptions::TooLargePayload.new if response.status == 413
      raise Exceptions::OwOInternalError.new if response.status == 500
      return UploadedFile.from_json response.body
    end

    # `#upload_file` is generally the same as `#upload_data`, however it tries to guess Content-Type and also inputs from a file.
    # Take note this stores the entire file into memory.
    #
    # All exceptions specified in `#upload_data` apply here with the same reasons.
    #
    # It returns an instance of `UploadedFile`.
    def upload_file(data : File, contenttype : String? = nil)
      raise Exceptions::TooLarge.new if data.size > 100*1024*1024
      read = Bytes.new data.size
      data.read read
      return upload_data read, data.path.split(File::SEPARATOR).pop, OwO.content_type(data)
    end

    # `#shorten` shortens the `String` URI or the `URI` instance as input.
    # The single parameter *uri* specifies the `String` or `URI` to shorten and must be a standard UTF-8 URI.
    #
    # Under the following circumstances are exceptions raised:
    #
    #  - `OwO::Exceptions::Unauthorized` is raised if the `@token` value is deactivated.
    #  - `OwO::Exceptions::OwOInternalError` is raised if OwO has an internal error at their API.
    #
    # A 404 error is not handled by this library and may result in a panic.
    #
    # It returns a `String` which is the endpoint key for the CDN.
    # In order to access it, you'll need to prefix it with a valid CDN URI, found on the OwO FAQ.
    def shorten(uri : String | URI)
      response = @client.get(@api_uri + "/shorten/polr?action=shorten&url=" + uri.to_s)
      raise Exceptions::Unauthorized.new if response.status == 401
      raise Exceptions::OwOInternalError.new if response.status == 500
      url = response.body.lines.first
      return url.lchop "https://awau.moe/"
    end
  end
end
