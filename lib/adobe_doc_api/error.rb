module AdobeDocApi

  class Error < StandardError
    attr_reader :status_code

    def initialize(status_code:, msg:)
      super
      @status_code = status_code
      @msg = msg
    end

    def message
      case @status_code
      when 200 then "The operation has failed due to some reason before the wait time provided in the Prefer header specified in the request (if Prefer header was not specified then the wait time is 59s by default), for detailed error refer cpf:status field inside the response body. Expect 200 HTTP status code only when respond-async,wait=0 is NOT specified in the Prefer Header value while creating the request. Refer the response body structure from GET call 200 response."
      when 201 then "The operation is completed successfully before the wait time provided in the Prefer header specified in the request (if Prefer header was not specified then the wait time is 59s by default). Expect 201 HTTP status code only when respond-async,wait=0 is NOT specified in the Prefer Header value while creating the request. Refer the response body structure from GET call 200 response."
      when 400 then "#{@msg["title"]} : #{@msg["report"]["error_code"]}"
      when 408 then "Request Timed Out. Some operation has timed out due to client issue."
      when 429 then "Caller doesn't have sufficient quota for this operation."
      when 500 then "Internal Server Error. The server has encountered an error and is unable to process your request at this time."
      else
        @msg
      end
    end
  end

end
