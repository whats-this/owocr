module OwO
  # Defines the exceptions this library may use.
  # All exceptions have their own documentation.
  module Exceptions
    # `InvalidToken` is raised when the token is empty.
    class InvalidToken < Exception
    end

    # `Unauthorized` is raised when the token is deactivated at the OwO API.
    # This can also mean the token was miswritten.
    #
    # NOTE: This is raised if a token does not have the required dashes or has whitespace.
    class Unauthorized < Exception
    end

    # `OwOInternalError` is thrown upon an Internal Server Error HTTP error from the API.
    # It will never have any extra information.
    #
    # NOTE: In CLI applications this may be ignored, as they are usually made to fail with an exception.
    class OwOInternalError < Exception
    end

    # `TooLarge` is not to be confused with `TooLargePayload`. It is raised when the file or data is too large to send to the API.
    # There is never any extra information as to how large it is and the maximum.
    class TooLarge < Exception
    end

    # `TooLargePayload` is not to be confused with `TooLarge`. It is raised when the file or data is too large in the payload.
    # It is not too large in the data itself, and there is therefore decided by the extra data which was sent.
    #
    # NOTE: Cloudflare is usually the one to raise this.
    class TooLargePayload < Exception
    end
  end
end
