require "uri"
require "net/https"
require "digest/md5"
require "openssl"

module OpenSRS
  class Server
    attr_accessor :server, :username, :password, :key

    def initialize(options = {})
      @server   = URI.parse(options[:server] || "https://rr-n1-tor.opensrs.net:55443/")
      @username = options[:username]
      @password = options[:password]
      @key      = options[:key]
    end

    def call(options = {})
      attributes = {
        :protocol => "XCP"
      }
      
      xml = OpenSRS::XML.build(attributes.merge!(options))
      
      response = http.post(server.path, xml, headers(xml))
      parsed_response = OpenSRS::XML.parse(response.body)
      
      return OpenSRS::Response.new(parsed_response, xml, response.body)
    end
    
    private
    
    def headers(request)
      headers = {
        "Content-Length"  => request.length.to_s,
        "Content-Type"    => "text/xml",
        "X-Username"      => username,
        "X-Signature"     => signature(request)
      }
      
      return headers
    end
    
    def signature(request)
      signature = Digest::MD5.hexdigest(request + key)
      signature = Digest::MD5.hexdigest(signature + key)
      signature
    end
    
    def http
      http = Net::HTTP.new(server.host, server.port)
      http.use_ssl = (server.scheme == "https")
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http
    end
  end
end