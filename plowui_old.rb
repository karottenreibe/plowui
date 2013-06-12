#!/usr/bin/ruby
require 'simple_http'
require 'json'
require 'set'
require 'colorize'

# Quits the program with a descriptive message
def die(message)
  $stderr.puts message
  exit 1
end

# Reads values from the clipboard, but ignores values that were already read.
class UniqueClipboard

  def initialize
    @parsed_values = Set.new
  end

  # Returns the value in the clipboard or nil if none was found
  def read()
    value = %x{sh -c "xclip -out -selection c 2> /dev/null"}
    return nil if @parsed_values.include?(value)
    @parsed_values << value
    return value
  end

end

# Represents the online/offline status of a link or collection of links
class Status

  def initialize(status = 2)
    die "unknown status: #{s1}" unless status <= 3 and status > 0
    @status = status
  end

  # Assigns the union of this status and the given one to this status.
  def union!(status)
    s1 = self.to_i
    s2 = status.to_i
    if [s1, s2].include?(1)
      @status = 1
    elsif [s1, s2].include?(3)
      @status = 3
    else
      @status = 2
    end
  end

  def offline?
    return @status == 1
  end

  def to_i
    return @status
  end

  def to_s(colored = true)
    return case @status
      when 1 then "offline"
      when 2 then "online"
      when 3 then "unknown"
    end
  end

  def to_color
    case @status
      when 1 then :red
      when 2 then :green
      when 3 then :blue
    end
  end

end

class PyLoadClip

  def initialize(host, port)
    @host = host
    @port = port

    print "Enter your username: "
    @user = gets.strip
    print "Enter your password: "
    @password = gets.strip

    @clipboard = UniqueClipboard.new

    @rids = []
    @status_cache = Hash.new do |hash, key|
      hash[key] = {}
    end
  end

  # Performs a request to the pyLoad API
  def api(method, init_params)
    params = {}
    init_params.each do |key, value|
      params[key.to_s] = value.to_s
    end
    if @session
      params["session"] = @session
    end
    response = SimpleHttp.post("http://#{@host}:#{@port}/api/#{method}", params)
    return nil unless response
    return JSON.parse("[#{response}]").first
  end

  # Authenticates with pyLoad to get a session token
  def authenticate
    @session = api(:login, :username => @user, :password => @password)
    die "wrong login info" unless @session
  end

  # Try to find all URLs in the copied text
  def parse(str)
    return str.scan(/^(?:https?\:\/\/|www.)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(?:\/\S*)?$/).uniq
  end

  def start_online_check(links)
    ret = api(:checkOnlineStatus, :urls => links.to_json)
    return unless ret
    @rids << ret["rid"]
    puts "---> rid #{ret["rid"]}"
  end

  def status_text(status)
    case status
      when 1 then "offline"
      when 2 then "online"
      when 3 then "unknown"
    end
  end

  def recheck_status()
    new_rids = []

    @rids.each do |rid|
      ret = api(:pollResults, :rid => rid)
      unless ret["data"].empty?
        @status_cache[rid].merge!(ret["data"])
      end

      if ret["rid"] == -1
        data = @status_cache[rid]
        status = Hash.new do |hash,key|
          hash[key] = Status.new
        end
        data.each do |url,entry|
          plugin = entry["plugin"]
          if plugin != "BasePlugin"
            status[plugin].union!(entry["status"])
          end
        end

        status.each do |plugin, s|
          puts "rid #{rid} #{plugin.ljust(30)} is #{s}".colorize(s.to_color)
          links = data.keys.find_all { |url| data[url]["plugin"] == plugin }
          self.click_n_load(links) unless s.offline?
        end
      else
        new_rids << rid
      end
    end

    @rids = new_rids
  end

  # Adds the links via click'n'load to a download manager
  def click_n_load(links)
    SimpleHttp.post("http://localhost:9666/flash/add", "urls" => links.join("\r\n"))
  end

  # Runs the main loop
  def run
    self.authenticate()

    loop do
      value = @clipboard.read

      if value
        links = self.parse(value)
        unless links.empty?
          puts "-----------------"
          puts links
          self.start_online_check(links)
        end
      end

      self.recheck_status()
    end
  end

end

PyLoadClip.new("localhost", 8000).run

