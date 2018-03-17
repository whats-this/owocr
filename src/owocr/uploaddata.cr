module OwO
  struct UploadData
    property! data : Bytes
    property! filename : String
    property! content_type : String

    def initialize(@data : Bytes, @filename : String = "data.bin", @content_type : String = "application/octet-stream")
    end

    def initialize(file : File, name : String? = nil, type : String? = nil)
      read_bytes = Bytes.new file.size
      file.read read_bytes
      data= read_bytes
      filename= name || data.path.split(File::SEPARATOR).pop
      content_type= type || OwO.content_type file
    end
  end
end