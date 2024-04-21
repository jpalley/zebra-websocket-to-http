require 'rack'
require 'faye/websocket'
require 'json'
require 'thread'

class ZebraWebsocketApp
  def initialize
    @clients = []
    @clients_mutex = Mutex.new
  end

  def call(env)
    if Faye::WebSocket.websocket?(env)
      ws = Faye::WebSocket.new(env, nil, {ping: 15})

      ws.on :open do |event|
        puts "WebSocket connection opened"
        puts event.inspect
        @clients_mutex.synchronize do
          @clients << ws
        end
        ws.send("Connection established")
      end

      ws.on :message do |event|
        puts "WebSocket message received"
        puts event.inspect
        ws.send(event.data)  # Echoes back the incoming message
      end

      ws.on :close do |event|
        @clients_mutex.synchronize do
          @clients.delete(ws)
        end
        ws = nil
      end

      ws.rack_response

    elsif env["REQUEST_METHOD"] == "GET" && env["PATH_INFO"] == '/send_msg'
      request = Rack::Request.new(env)
      message = request.params["msg"]

      @clients_mutex.synchronize do
        @clients.each { |client| client.send(message) }
      end

      [200, {'Content-Type' => 'text/plain'}, ["Message broadcasted: #{message}"]]

    else
      puts "REQUEST======"
      puts "NOT FOUND"
      puts env.inspect
      [404, {'Content-Type' => 'text/plain'}, ['Not found']]
    end
  end
end
