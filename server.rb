require 'socket'

if ARGV.size != 2
	puts "You need to specify the port to forward, and the port where the recipient server will connect on"
  exit 1
end

# this listens on the port where this app is acting as a server
def server_listen
end

# this listens on the port for connections from the client
def client_listen
end

require 'async/io'

def echo_server(endpoint)
  Async do |task|
    puts "waiting for connection to server"
    # This is a synchronous block within the current task:
    endpoint.accept do |client|
      puts "got connection to server"
      # This is an asynchronous block within the current reactor:
      data = client.read

      # This produces out-of-order responses.
      task.sleep(rand * 0.01)

      client.write(data.reverse)
      client.close_write
    end
  end
end

def echo_client(endpoint, data)
  Async do |task|
    puts "about to connect to server"
    endpoint.connect do |peer|
      peer.write(data)
      peer.close_write

      message = peer.read

      puts "Sent #{data}, got response: #{message}"
    end
  end
end

Async do
  puts "creating endpoint"
  endpoint = Async::IO::Endpoint.tcp('127.0.0.1', 9000)
  puts "about to create server"
  server = echo_server(endpoint)
puts "about to create 5 clients"
  5.times.map do |i|
    echo_client(endpoint, "Hello World #{i}")
  end.each(&:wait)

  server.stop
end