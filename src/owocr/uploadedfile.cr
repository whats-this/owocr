require "json"

module OwO
  # `UploadedFile` contains data as to what files were uploaded to the API.
  # As of `VERSION` 0.1.0, `UploadedFile#files` never has more than 1 item.
  class UploadedFile
    JSON.mapping(
      success: Bool,
      files: Array(UploadedFileData),
    )

    def initialize(@success : Bool, @files : Array(UploadedFileData))
    end
  end

  # `UploadedFileData` contains data to the actual files which were uploaded.
  #
  # The following fields are in use:
  #
  #  - **hash** is the entire data hash. This can be used to verify the file which was sent.
  #  - **name** is the name of the file sent, as specified by the file name in the upload method.
  #  - **url** is the URI endpoint to the CDN. It must have a valid CDN domain as a prefix to visit.
  #  - **size** is the total size of the file. This is useful to show users where the library is used.
  class UploadedFileData
    JSON.mapping(
      hash: String,
      name: String,
      url: String,
      size: Int64,
    )

    def initialize(@hash : String, @name : String, @url : String, @size : Int64)
    end
  end
end
