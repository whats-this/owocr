module OwO
  class UploadedFile
    JSON.mapping(
      success: Bool,
      files: Array(UploadedFileData),
    )

    def initialize(@success : Bool, @files : Array(UploadedFileData))
    end
  end

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
