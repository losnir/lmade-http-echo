# An http server written in Crystal that echo's any request back in JSON format

# Hack to prevent a segfault for static linking
# Source: https://hub.docker.com/r/jrei/crystal-alpine
{% if flag?(:static) %}
  require "llvm/lib_llvm"
  require "llvm/enums"
{% end %}

require "http/server"
require "json"

require "./metrics"

# Handle SIGINT & SIGTERM signals
Signal::INT.trap { STDERR << "Caught SIGINT, bye...\n"; exit }
Signal::TERM.trap { STDERR << "Caught SIGTERM, bye...\n"; exit }

# Read configuration from environment variables
bind_host = ENV["BIND_ADDR"]? || "0.0.0.0"
bind_port = ENV["BIND_PORT"]?.try(&.to_i32?) || 8080
metrics_endpoint_host = ENV["METRICS_ENDPOINT_HOST"]?
metrics_endpoint_port = ENV["METRICS_ENDPOINT_PORT"]?.try(&.to_i32?)

if metrics_endpoint_host && metrics_endpoint_port
  puts "Reporting UDP metrics to: #{metrics_endpoint_host}:#{metrics_endpoint_port}"
  _m = UDPMetricReporter.new metrics_endpoint_host.to_s, metrics_endpoint_port
else
  _m = NoOpMetricReporter.new
end

class EchoJsonHandler
  include HTTP::Handler
  
  def initialize(metricReporter : BaseMetricReporter)
    @metricReporter = metricReporter
  end

  def call(context : HTTP::Server::Context)
    start = Time.utc

    context.response.status = HTTP::Status::OK
    context.response.content_type = "application/json"
    context.request.body.try(&.set_encoding("UTF-8"))

    headerXFF = context.request.headers["X-Forwarded-For"]?
    remote_client = headerXFF.try(&.split(',')[0].try(&.strip()))

    json_response = {
        "method" => context.request.method,
        "version" => context.request.version,
        "host" => context.request.host,
        "path" => context.request.path,
        "query" => context.request.query,
        "headers" => context.request.headers.to_json(),
        "body" => context.request.body.try(&.gets_to_end()),
        "content_length" => context.request.content_length,
        "remote_address" => context.request.remote_address.try(&.to_s),
        "remote_client" => remote_client
    }
    json_response.to_json(context.response)

    total = Time.utc - start
    @metricReporter.count("http-echo.hits")
    @metricReporter.histogram("http-echo.time", total.total_milliseconds.to_s)
  end
end

server = HTTP::Server.new([
  HTTP::ErrorHandler.new,
  HTTP::LogHandler.new,
  EchoJsonHandler.new _m
])

address = server.bind_tcp bind_host, bind_port
puts "Server listening on http://#{address}"
server.listen