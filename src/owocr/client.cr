require "./version.cr"
require "json"
require "uri"
require "http"
require "cossack"
require "./contenttype.cr"
require "./uploadedfile.cr"
require "./uploaddata.cr"

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
    #    If the token is empty, it will raise an `Exceptions::InvalidToken` exception.
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
        client.headers["User-Agent"] = user_agent
        client.headers["Authorization"] = @token
        client.use Cossack::RedirectionMiddleware
      end
    end

    # The base URI for all normal data uploaded.
    # This gets prepended to every `url` field in the `OwO::UploadedFileData` objects.
    #
    # NOTE: This only applies to `#upload_data` and `#upload_file`.
    property data_base : String? = nil

    # The base URI for all shortenings.
    # This gets prepended to the shortened URI return.
    #
    # NOTE: This only applies to `#shorten`.
    property shorten_base : String? = nil

    # `upload` uploads data given by `OwO::UploadData` by passing it to the overloaded `#upload`
    # method which takes three of them and spits out a tuple of three nullable `OwO::UploadedFile`.
    #
    # All this does is call `#upload` with two nil arguments and get the first tuple member.
    #
    # Under the following circumstances are exceptions raised:
    #
    #  - `Exceptions::Unauthorized` is raised if the `@token` value is deactivated.
    #  - `Exceptions::TooLargePayload` is raised if OwO changes the payload max size before this library updates.
    #  - `Exceptions::TooLarge` is raised if you upload data over the size of 100MiB.
    #  - `Exceptions::OwOInternalError` is raised if OwO has an internal error at their API.
    #
    # A 404 error is not handled by this library and may result in a panic.
    #
    # NOTE: The return is nullable and there is no guarantee this conforms to your needs.
    def upload(data : UploadData)
      return upload(data, nil, nil)[0]?
    end

    # `#upload` uploads the data from `OwO::UploadData` objects.
    # You can pass up to three, as that's what OwO limits it at, but if it were higher, there would be more support.
    #
    # Under the following circumstances are exceptions raised:
    #
    #  - `Exceptions::Unauthorized` is raised if the `@token` value is deactivated.
    #  - `Exceptions::TooLargePayload` is raised if OwO changes the payload max size before this library updates.
    #  - `Exceptions::TooLarge` is raised if you upload data over the size of 100MiB.
    #  - `Exceptions::OwOInternalError` is raised if OwO has an internal error at their API.
    #
    # A 404 error is not handled by this library and may result in a panic.
    #
    # It does not return `OwO::UploadedFile` as it did in v0.1.0, however it returns `OwO::UploadedFileData`.
    # In this case it however returns it as `Tuple(UploadedFileData?, UploadedFileData?, UploadedFileData?)`.
    def upload(first : UploadData, second : UploadData?, third : UploadData? = nil)
      total = first.data.size
      total += second.data.size if !second.nil?
      total += third.data.size if !third.nil?
      raise Exceptions::TooLarge.new if total > 100*1024*1024
      io = IO::Memory.new
      boundary = HTTP::Multipart.generate_boundary
      multipart = HTTP::Multipart::Builder.new(io, boundary)
      add_multipart first, multipart
      add_multipart second, multipart
      add_multipart third, multipart
      multipart.finish
      response = @client.post(@api_uri + "/upload/pomf", io.to_s) do |req|
        req.headers["Content-Type"] = "multipart/form-data; boundary=" + boundary
      end
      raise Exceptions::Unauthorized.new if response.status == 401
      raise Exceptions::TooLargePayload.new if response.status == 413
      raise Exceptions::OwOInternalError.new if response.status == 500
      uploaded = UploadedFile.from_json response.body
      base = get_proper_data_base
      if !base.nil?
        uploaded.files.each do |data|
          data.url = base + data.url
        end
      end
      return {uploaded.files[0]?, uploaded.files[1]?, uploaded.files[2]?}
    end

    # `#shorten` shortens the `String` URI or the `URI` instance as input.
    # The single parameter *uri* specifies the `String` or `URI` to shorten and must be a standard UTF-8 URI.
    #
    # Under the following circumstances are exceptions raised:
    #
    #  - `Exceptions::Unauthorized` is raised if the `@token` value is deactivated.
    #  - `Exceptions::OwOInternalError` is raised if OwO has an internal error at their API.
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
      url = url.lchop "https://awau.moe/"
      base = get_proper_shorten_base || return url
      url = base + url
      return url
    end

    # This is an internal method to get a properly formatted URI of the `#data_base` output.
    private def get_proper_data_base
      base = data_base || return nil
      return "https://" + base.lchop("https").lchop("http").lstrip(':').lstrip('/').rstrip('/') + '/'
    end

    # This is an internal method to get a properly formatted URI of the `#shorten_base` output.
    private def get_proper_shorten_base
      base = shorten_base || return nil
      return "https://" + base.lchop("https").lchop("http").lstrip(':').lstrip('/').rstrip('/') + '/'
    end

    private macro add_multipart(name, multipart)
    {{multipart}}.body_part HTTP::Headers{
      "Content-Disposition" => "form-data; name=\"files[]\"; filename=\"" + {{name}}.filename + "\"",
      "Content-Type"        => {{name}}.content_type,
    }, {{name}}.data if !{{name}}.nil?
    end
  end
end
