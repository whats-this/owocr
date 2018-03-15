# owo.cr

A wrapper in [Crystal](https://crystal-lang.org) for the [OwO What's This?](https://owo.whats-th.is) file sharing service.

## Instructions (Developers)

1. Add this as a dependency to your `shards.yml`:

```yaml
dependencies:
  owocr:
    github: Proximyst/owocr
    branch: master
```

1. Run `crystal deps` or `shards update`
1. Check the usage below

## Usage

First a client is needed:

```crystal
require "owocr"

client = OwO::WhatsThis.new "token", "optional user-agent for the requests"
```

You will then need to utilise one of the methods as listed:

  1. `OwO::WhatsThis#shorten(url : String|URI) : String` - Returns the CDN endpoint.
  1. `OwO::WhatsThis#upload_file(data : File, contenttype : String? = nil) : UploadedFile` - Returns the [API data](src/owocr/uploadedfile).
  1. `OwO::WhatsThis#upload_data(data : Bytes, file_name : String, content_type : String) : UploadedFile` - Returns the API data.
