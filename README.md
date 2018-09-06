# owocr

[![Build Status](https://travis-ci.org/whats-this/owocr.svg?branch=master)](https://travis-ci.org/whats-this/owocr)

A wrapper in [Crystal](https://crystal-lang.org) for the [OwO What's This?](https://owo.whats-th.is) file sharing service.

## Instructions (Developers)

1. Add this as a dependency to your `shards.yml`:

```yaml
dependencies:
  owocr:
    github: whats-this/owocr
    branch: master # as of now this requires 0.24.2 at the very least
```

1. Run `crystal deps` or `shards update`
1. Check the usage below

## Usage

First a [client](https://whats-this.owo.codes/owocr/OwO/WhatsThis.html) is needed:

```crystal
require "owocr"

client = OwO::WhatsThis.new "token", "optional user-agent for the requests", "optional api url"
```

You will then need to utilise one of the methods as listed:

  1. [`OwO::WhatsThis#shorten(url : String|URI) : String`](https://whats-this.owo.codes/owocr/OwO/WhatsThis.html#shorten%28uri%3AString%7CURI%29-instance-method) - Shortens the given URL or URI and returns the shortened ID.
  1. [`OwO::WhatsThis#upload(first : UploadData, second : UploadData?, third : UploadData? = nil) : Tuple(UploadedFileData?, UploadedFileData?, UploadedFileData?)`](https://whats-this.owo.codes/owocr/OwO/WhatsThis.html#upload%28first%3AUploadData%2Csecond%3AUploadData%3F%2Cthird%3AUploadData%3F%3Dnil%29-instance-method) - Uploads the file(s) and returns the uploaded file(s).

For more in-depth explanation of these, you can go to the [OwO.codes API page](https://whats-this.owo.codes/owocr).
