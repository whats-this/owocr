module OwO
  # The function guesses what Content-Type a file may have from its extension.
  # If the extension is unknown or non-existant, it will return "application/octet-stream".
  def self.content_type(file : File)
    case File.extname(file.path)
    when ".txt"                             then "text/plain"
    when ".htm", ".html", ".xhtm", ".xhtml" then "text/html"
    when ".css"                             then "text/css"
    when ".js"                              then "application/javascript"
    when ".svg"                             then "image/svg+xml"
    when ".jpg", ".jpeg"                    then "image/jpeg"
    when ".png"                             then "image/png"
    when ".avi"                             then "video/avi"
    when ".bmp"                             then "image/bmp"
    else                                         "application/octet-stream"
    end
  end
end
