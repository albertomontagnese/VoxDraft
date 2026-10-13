#!/usr/bin/env ruby
# Minimal App Store Connect API client. Credentials come only from environment.
require "base64"
require "json"
require "net/http"
require "openssl"

method, path, body_path = ARGV
abort "usage: asc_api.rb METHOD /v1/path [json-file]" unless method && path
key = OpenSSL::PKey.read(File.read(ENV.fetch("ASC_PRIVATE_KEY")))
encode = ->(value) { Base64.urlsafe_encode64(value, padding: false) }
header = encode.call({ alg: "ES256", kid: ENV.fetch("ASC_KEY_ID"), typ: "JWT" }.to_json)
now = Time.now.to_i
claims = encode.call({ iss: ENV.fetch("ASC_ISSUER_ID"), iat: now, exp: now + 600,
                       aud: "appstoreconnect-v1" }.to_json)
signature_der = key.sign(OpenSSL::Digest::SHA256.new, "#{header}.#{claims}")
signature = OpenSSL::ASN1.decode(signature_der).value.map do |integer|
  [integer.value.to_s(16).rjust(64, "0")].pack("H*")
end.join
token = "#{header}.#{claims}.#{encode.call(signature)}"

url = URI("https://api.appstoreconnect.apple.com#{path}")
abort "invalid API path" unless url.host == "api.appstoreconnect.apple.com"
request = Net::HTTP.const_get(method.capitalize).new(url)
request["Authorization"] = "Bearer #{token}"
request["Content-Type"] = "application/json"
request.body = File.read(body_path) if body_path
response = Net::HTTP.start(url.host, url.port, use_ssl: true) { |http| http.request(request) }
puts "HTTP #{response.code}"
begin
  puts JSON.pretty_generate(JSON.parse(response.body))
rescue JSON::ParserError
  puts response.body
end
exit response.code.to_i.between?(200, 299) ? 0 : 1
