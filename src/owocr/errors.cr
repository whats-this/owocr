module OwO
  module Exceptions
    class InvalidToken < Exception
    end

    class Unauthorized < Exception
    end

    class OwOInternalError < Exception
    end

    class TooLarge < Exception
    end

    class TooLargePayload < Exception
    end
  end
end
