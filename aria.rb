require 'simple_http'
require 'xmlrpc/client'

# Provides access to an aria2c instance running with RPC enabled.
class Aria

  # Accepted options are:
  # :user => the user name for authentication with the server
  # :password => the password for authentication with the server
  # :port => The port to connect to
  # :host => The host to connect to
  def initialize(opts)
    default_opts = {
      :port => 6800,
      :host => "localhost"
    }
    opts = default_opts.merge(opts)
    @server = XMLRPC::Client.new(opts[:host], "/rpc", opts[:port],
        nil, nil, opts[:user], opts[:password])
  end

  # Adds the given link to the server and starts it.
  def add(link)
    @server.call("aria2.addUri", [link])
    return true
  rescue XMLRPC::FaultException => e
    $log.error("could not contact aria2: #{e.faultString}")
    return false
  end

end

