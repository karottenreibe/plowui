require 'open4'
require 'thread'

# Class for interfacing with plowshare's executables.
class Plowshare::API

  def initialize
    @resolvers = []
    @resolvables = []
    @mutex = Mutex.new
  end

  # Starts a thread that resolves the given link.
  def resolve(link, id)
    resolver = Plowshare::Resolver.new(link, id, self)
    @resolvers << resolver
  end

  # Adds a resolvable to the result list.
  def add_result(resolvable)
    @mutex.synchronize do
      @resolvables << resolvable
    end
  end

  # Returns all IDs that have been resolved.
  def done_ids
    done_resolvers = @resolvers.find_all(&:done?)
    @resolvers.reject! do |resolver|
      done_resolvers.include?(resolver)
    end
    return done_resolvers.map(&:id)
  end

  # Returns all done resolvables.
  def results
    @mutex.synchronize do
      resolvables = @resolvables
      @resolvables = []
      return resolvables
    end
  end

  # Call plowlist to resolve folders and crypters.
  # If links were found, returns them as an array.
  # Otherwise returns nil.
  def list(link)
    # TODO
  end

  # Call plowprobe to get info about a link.
  # Returns the gathered info.
  # If an error occurred, returns nil.
  def probe(link)
    output = call("plowprobe #{link} --printf '%c%n%m%n%f%n%s'")
    return nil unless output

    lines = output.split(/\n/)
    status = Status.from_plowshare(lines[0].to_i)
    hoster = lines[1]
    name = lines[2]
    size = lines[3].to_i

    return {
      :size => size,
      :status => status,
      :hoster => hoster,
      :name => name,
    }
  end

  # Call plowdown to obtain a download link.
  # Returns the download link.
  # If an error occurred, returns nil.
  #
  # If entering a captcha is required, calls the
  # given block
  def down(link)
    # TODO
  end

  # Executes the given command and returns the result.
  # If the command exits with a non-zero exit code, returns nil.
  def call(command)
    output = nil
    $log.debug("exec #{command}")
    status = Open4::popen4(command) do |pid, stdin, stdout, stderr|
      output = stdout.read
      errors = stderr.read
      $log.debug("stderr = #{errors}") if errors
    end
    return nil unless status.to_i == 0
    return output
  end

end

