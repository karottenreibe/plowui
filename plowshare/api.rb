require 'open3'
require 'thread'

# Class for interfacing with plowshare's executables.
class Plowshare::API

  def initialize
    @resolvers = []
    @resolvables = []
    @attempts = []
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
  def resolved_ids
    return get_and_remove_done(@resolvers).map(&:id)
  end

  # Returns all :done? items from the given collection and also removes
  # them from it.
  def get_and_remove_done(collection)
    done_resolvers = collection.find_all(&:done?)
    collection.reject! do |resolver|
      done_resolvers.include?(resolver)
    end
    return done_resolvers
  end

  # Returns all done resolvables.
  def results
    @mutex.synchronize do
      resolvables = @resolvables
      @resolvables = []
      return resolvables
    end
  end

  # Returns a list of attempts that need captcha solving.
  def captcha_attempts
    return @attempts.find_all?(&:needs_captcha?)
  end

  # Returns all download attempts that are done.
  def done_download_attempts
    return get_and_remove_done(@attempts)
  end

  # Call plowlist to resolve folders and crypters.
  # If links were found, returns them as an array.
  # Otherwise returns nil.
  # Also returns a status object based on the exit code of the call.
  def list(link)
    output, status = call("plowlist #{link} --printf '%u' -R")
    return nil, status unless output

    return output.split(/\n/), status
  end

  # Call plowprobe to get info about a link.
  # Returns the gathered info.
  # If an error occurred, returns nil.
  # Also returns a status object based on the exit code of the call.
  def probe(link)
    output, status = call("plowprobe #{link} --printf '%c%n%m%n%f%n%s'")
    return nil, status unless output

    lines = output.split(/\n/)
    status = Status.from_plowshare(lines[0].to_i)
    hoster = lines[1]
    name = lines[2]
    size = lines[3].to_i
    info = {
      :size => size,
      :status => status,
      :hoster => hoster,
      :name => name,
    }

    return info, status
  end

  # Tries to resolve the given link and add it to aria.
  def down(link)
    @attempts << Plowshare::DownloadAttempt.new(link)
  end

  # Executes the given command and returns the result.
  # If the command exits with a non-zero exit code, returns nil.
  # Also returns a status object based on the exit code of the call.
  def call(command)
    $log.debug("exec #{command}")

    stdout, stderr, exit_status = Open3::capture3(ENV, command)
    $log.debug("stderr = #{stderr}") if stderr
    $log.debug("stdout = #{stdout}")
    $log.debug("exit status = #{exit_status}")

    status = Status.from_plowshare(exit_status.exitstatus)
    $log.debug("status = #{status}")

    return nil, status unless exit_status.success?
    return stdout, status
  end

end

